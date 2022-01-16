// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');
require('dotenv').config();

const HOLDER_ADDRESS = '0xC76e750c31eA0AeF85d53F73782C8d630836047d'

const deploySeaToken = async () => {
  const SeaToken = await hre.ethers.getContractFactory('SeaToken');
  const seaToken = await SeaToken.deploy(HOLDER_ADDRESS);

  await seaToken.deployed();
  console.log('[deploySeaToken] seaToken deployed to ', seaToken.address);
};

async function main() {
  await deploySeaToken();
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
