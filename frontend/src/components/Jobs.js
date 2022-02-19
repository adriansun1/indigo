import React from 'react';
import Grid from '@mui/material/Grid';
import Box from '@mui/material/Box';
import PropTypes from 'prop-types';
import ModelCard from 'components/ModelCard';

const mock = [
  {
    modelName: 'Sushi Defi dApp Data',
    dapps: ['sushiswap'],
    address: '0x12345',
    description:
      'locavore tbh health goth street art tumblr 3 wolf moon single-origin coffee vexillologist +1 skateboard taxidermy copper mug master cleanse hexagon kitsch.',
    feeTotal: '7',
    url:'312'
  },
  {
    modelName: 'Near + Sushi Volume',
    dapps: ['sushiswap', 'near'],
    address: '0x12345',
    description:
      'locavore tbh health goth street art tumblr 3 wolf moon single-origin coffee vexillologist +1 skateboard taxidermy copper mug master cleanse hexagon kitsch.',
    feeTotal: '7',
    url:'312'
  },
  {
    modelName: 'Aurora + Curve',
    dapps: ['aurora', 'curve'],
    address: '0x12345',
    description:
      'locavore tbh health goth street art tumblr 3 wolf moon single-origin coffee vexillologist +1 skateboard taxidermy copper mug master cleanse hexagon kitsch.',
    feeTotal: '7',
    url:'312'
  },
  {
    modelName: 'Data Correlation',
    dapps: ['sushiswap', 'twitter', 'curve', 'chainlink'],
    address: '0x12345',
    description:
      'locavore tbh health goth street art tumblr 3 wolf moon single-origin coffee vexillologist +1 skateboard taxidermy copper mug master cleanse hexagon kitsch.',
    feeTotal: '7',
    url:'312'
  },
  {
    modelName: 'Ecosystem data',
    dapps: ['twitter', 'chainlink', 'near', 'terra', 'curve'],
    address: '0x12345',
    description:
      'locavore tbh health goth street art tumblr 3 wolf moon single-origin coffee vexillologist +1 skateboard taxidermy copper mug master cleanse hexagon kitsch.',
    feeTotal: '7',
    url:'312'
  },
];

const Jobs = ({ data }) => {
  data=data.concat(mock);
  return (
    <Box>
      <Grid container spacing={4} height='100%'>
        {data.map((item, i) => (
          <ModelCard item={item} key={item.modelName + i} />
        ))}
      </Grid>
    </Box>
  );
};

Jobs.propTypes = {
  data: PropTypes.array,
};

export default Jobs;
