// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');
require('dotenv').config();

const INITIAL_TOKEN_HOLDER_ADDRESS = '0x88a31C48BDDFbc2d9e4cF58b7193dc87B5dB1320';
const FEE_ADDRESS = '0x88a31C48BDDFbc2d9e4cF58b7193dc87B5dB1320';
const WBNB = '0xae13d989dac2f0debff460ac112a837c89baa7cd';
const FEE_RATE = 200;
const CLOSED_SEA_TOKEN = '0xA4fb840986B10aC44aA893793cfe755c81c3740D';
const CLOSED_SEA_NFT = '0x69536bdf4B18499181EB386B0E4019a28C4Fb096';
const CLOSED_SEA_CONTROLLER = '0xC4079Eb296408e56AEEED634b11E6C7c72fb7f45';

const deploySeaToken = async () => {
  const SeaToken = await hre.ethers.getContractFactory('SeaToken');
  const seaToken = await SeaToken.deploy(INITIAL_TOKEN_HOLDER_ADDRESS);

  await seaToken.deployed();
  console.log('[deploySeaToken] seaToken deployed to ', seaToken.address);
};

const deployClosedSeaController = async () => {
  const ClosedSeaNFTController = await hre.ethers.getContractFactory('ClosedSeaNFTController');
  const closedSeaNFTController = await ClosedSeaNFTController.deploy(CLOSED_SEA_NFT, WBNB, CLOSED_SEA_TOKEN, FEE_ADDRESS, FEE_RATE);

  await closedSeaNFTController.deployed();
  console.log('[deployClosedSeaController] ClosedSeaNFTController deployed to : ', closedSeaNFTController.address);
}

const deployClosedSeaNFT = async () => {
  const ClosedSeaNFT = await hre.ethers.getContractFactory('ClosedSeaNFT');
  const closedSeaNFT = await ClosedSeaNFT.deploy(FEE_ADDRESS, '1000000000000000', '100000000000000000000', CLOSED_SEA_TOKEN);
  await closedSeaNFT.deployed();

  console.log('[deployClosedSeaNFT] closedSeaNFT deployed to : ', closedSeaNFT.address);
}

async function main() {
  // await deploySeaToken();
  // await deployClosedSeaNFT();
  await deployClosedSeaController();
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
