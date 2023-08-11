module.exports = {
  contracts_directory: "../contracts",
  networks: {
    mainnet: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 100,
      feeLimit: 15000000000,
      fullHost: 'https://api.trongrid.io',
      network_id: '1'
    },
    dev: {
      privateKey:
        "0000000000000000000000000000000000000000000000000000000000000001",
      userFeePercentage: 0,
      feeLimit: 1000 * 1e6,
      fullHost: "http://127.0.0.1:9090",
      network_id: "9",
    },
    nile: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 100,
      feeLimit: 15000000000,
      fullHost: 'https://nile.trongrid.io',
      network_id: '3'
    },
    shasta: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 50,
      feeLimit: 15000000000,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '2'
    },
    compilers: {
      solc: {
        version: "0.8.6",
      },
    },
    solc: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "istanbul",
    },
  },
};
// source .env && tronbox migrate --reset --network nile