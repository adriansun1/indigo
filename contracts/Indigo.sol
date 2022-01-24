// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Models is ERC721URIStorage {
    uint256 private _tokensCount = 0;
    mapping (string => address) internal _modelOwners;
    mapping (string => uint64) internal _modelFees;

    event MintModel(string indexed _modelName, address indexed _author, uint256 tokenId, string _cloneUrl);

    constructor() ERC721("IndigoNFTs", "INFT") {}

    function modelNameAvailable(string memory _name) 
        public view
        returns (bool) 
    {
        return  _modelOwners[_name] == address(0);
    }

    function _formatMetaData(string memory name, string memory cloneUrl, uint64 ipFee) 
        private pure 
        returns (string memory) 
    {
        string[3] memory fields;

        fields[0] = string(abi.encodePacked('{"name": "', name, '",'));
        fields[1] = string(abi.encodePacked('"cloneUrl": "', cloneUrl, '",'));
        fields[2] = string(abi.encodePacked('"ipFee": ', Strings.toString(ipFee), '}'));

        return string(abi.encodePacked('data:application/json;base64,',
                                        fields[0], fields[1], fields[2]));
    }

    function mintModel(string memory name, string memory cloneUrl) public {
        // Use defaul IP Fee
        uint64 ipFee = 1;
        mintModelWithPrice(name, cloneUrl, ipFee);
    }

    function mintModelWithPrice(
        string memory name, 
        string memory cloneUrl, 
        uint64 ipFee) 
        public 
    {
        require(modelNameAvailable(name), 
                string(abi.encodePacked("Model name '", name, 
                                        "' not available: please try again")));
       
        uint256 tokenId = _tokensCount + 1;
        _safeMint(msg.sender, tokenId);
        
        _tokensCount = tokenId;
        _modelOwners[name] = msg.sender;
        _modelFees[name] = ipFee;

        _setTokenURI(tokenId, _formatMetaData(name, cloneUrl, ipFee));
        emit MintModel(name, msg.sender, tokenId, cloneUrl);
    }

}


contract Nodes {
    address private _admin = address(0);
    uint64 private _STAKE_MIN = 1000;
    CoinInterface private _coin;

    mapping (string => address) internal _liveModels;
    mapping (string => uint64) internal _gasFees;
    mapping (address => string) internal _registeredNodeUrls;
    mapping (address => uint64) private _nodeStake;

    event RegisterNode(address indexed _address, string _url);
    event PublishModel(string indexed _modelName, address indexed _address, string _url, uint256 _gasConsumed);

    modifier onlyAdmin() {
        require(
            _admin == msg.sender,
            'Invalid Minter'
        );
        _;
    }

    constructor(CoinInterface coin) {
        _admin = msg.sender;
        _coin = coin;
    }

    function stakeNode() public {
        require(_coin.balanceOf(msg.sender) >= _STAKE_MIN, 
                "Account does not have enough Indigo Coin to stake DB Node");

        _coin.burnCoins(msg.sender, msg.sender, _STAKE_MIN);
        _nodeStake[msg.sender] = _STAKE_MIN;
    }

    function slashStake(address nodeAddress) public onlyAdmin {
        uint64 _returnAmount = _nodeStake[nodeAddress];
        _coin.mintCoins(msg.sender, nodeAddress, _returnAmount);
        _nodeStake[nodeAddress] = 0;
    }

    function removeNode(address nodeAddress) public {
        require(msg.sender == _admin || msg.sender == nodeAddress,
                "Not authorized to remove db node");
        
        _registeredNodeUrls[nodeAddress] = "";
    }

    function returnStake(address nodeAddress) public view {
        require(msg.sender == _admin || msg.sender == nodeAddress,
                "Not authorized to unstake");
        // Not yet implemented
    }

    function registerNode(string memory nodeUrl) public {
        require(_nodeStake[msg.sender] >= _STAKE_MIN,
                "Must provide minimum stake before registering node");
        
        _registeredNodeUrls[msg.sender] = nodeUrl;
        
        emit RegisterNode(msg.sender, nodeUrl);
    }

    function publishModel(string memory modelName, uint64 gasFee) public {
        require(bytes(_registeredNodeUrls[msg.sender]).length != 0,
                "Must be registered node to publish model");

        _liveModels[modelName] = msg.sender;
        _gasFees[modelName] = gasFee;

        emit PublishModel(
            modelName, 
            msg.sender, 
            _registeredNodeUrls[msg.sender], 
            gasFee
        );
    }
}

struct Fees {
    string modelName;
    string nodeUrl;
    uint64 ipFee;
    address modelOwner;
    uint gasFee;
    address nodeAddress;
}

abstract contract Customer is ERC721URIStorage {
    address private _admin = address(0);
    uint64 private _tokensMinted = 0;
    mapping(address => mapping(string => uint160)) _customerReceipts;
    CoinInterface private _coin;

    constructor(CoinInterface coin) {
        _admin = msg.sender;
        _coin = coin;
    }

    function _payForModel(Fees memory fees) internal returns (uint160) {
        _coin.transferCoins(msg.sender, fees.modelOwner, fees.ipFee);
        _coin.transferCoins(msg.sender, fees.nodeAddress, fees.gasFee);
        uint160 receipt = _mintReceipt(fees.modelName, fees.nodeUrl, fees.nodeAddress);
        return receipt;
    }

    function burnReceipt(uint160 tokenId, string memory modelName) 
        public
        returns (bool)
    {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) ||
            msg.sender == _admin,
            "Not approved to burn receipt"
        );

        _burn(tokenId);
        _customerReceipts[msg.sender][modelName] = uint160(0);
        return true;
    }

    function getReceipt(string memory modelName) public view returns (uint160) {
        require(_customerReceipts[msg.sender][modelName] != uint160(0),
                "No valid receipts for model." );
        return _customerReceipts[msg.sender][modelName];
    }

    function _mintReceipt(
        string memory modelName, 
        string memory nodeUrl, 
        address nodeAddress) 
        internal
        returns (uint160)
    {   
        require(_customerReceipts[msg.sender][modelName] == uint160(0),
                "Already paid for model. Check receipts." );

        _tokensMinted += 1;
        uint160 tokenId = uint160(msg.sender) + _tokensMinted;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _formatMetaData(modelName, nodeUrl));

        approve(nodeAddress, tokenId);
        _customerReceipts[msg.sender][modelName] = tokenId;
        return tokenId;
    }

    function _formatMetaData(string memory name, string memory nodeUrl) 
        private pure 
        returns (string memory) 
    {
        string[2] memory fields;

        fields[0] = string(abi.encodePacked('{"name": "', name, '",'));
        fields[1] = string(abi.encodePacked('"cloneUrl": "', nodeUrl, '"}'));

        return string(abi.encodePacked('data:application/json;base64,',
                                        fields[0], fields[1]));
    }
    
}

interface CoinInterface is IERC20 {
    function burnCoins(address, address, uint256) external;
    function mintCoins(address, address, uint64) external;
    function transferCoins(address, address, uint256) external;
} 


contract Coin is ERC20, CoinInterface {
    address private _admin = address(0);

    constructor(address admin) ERC20("IndigoCoin", "INDC") {
        _admin = admin;
    }

    function burnCoins(address _sender, address _from, uint256 _amount) public override {
        require(_sender == _from, "Not token owner. Unauthorized to burn tokens");
        _burn(_from, _amount);
    }

    function mintCoins(address _sender, address _to, uint64 _amount) public override {
        require(_sender == _admin, //|| freeTrial(msg.sender)
                "Unauthorized to mint new coins");
        _mint(_to, _amount);
    }

    function transferCoins(address _sender, address _to, uint256 _amount) public override {
        _transfer(_sender, _to, _amount);
    }
}


contract Indigo is Models, Nodes, Customer {
    address private _admin = address(0);
    CoinInterface coin = new Coin(msg.sender);

    constructor() Customer(coin) Nodes(coin) {
        _admin = msg.sender;
    }

    function getModel(string memory modelName) 
        public payable 
        returns (uint160)
    {
        Fees memory fees = getFeesForModel(modelName);

        uint160 receipt = Customer._payForModel(fees);
        return receipt;
    }

    function getFeesForModel(string memory modelName) 
        public view
        returns (Fees memory)
    {   
        address nodeAddress = Nodes._liveModels[modelName];

        return Fees({
            modelName: modelName,
            nodeUrl: Nodes._registeredNodeUrls[nodeAddress],
            ipFee: Models._modelFees[modelName],
            modelOwner: Models._modelOwners[modelName],
            gasFee: Nodes._gasFees[modelName],
            nodeAddress: nodeAddress
        });
    }

    function mintCoins(address _to, uint64 _amount) public {
        coin.mintCoins(msg.sender, _to, _amount);
    }

    function coinBalance(address _account) public view returns (uint256) {
        return coin.balanceOf(_account);
    }
    

}