require('dotenv').config();
const hre = require('hardhat');

const SEA_TOKEN_ADDRESS = '0xA4fb840986B10aC44aA893793cfe755c81c3740D';
const CLOSEDSEA_NFT_ADDRESS = '0x69536bdf4B18499181EB386B0E4019a28C4Fb096';
const HOLDER_ADDRESS = '0x88a31C48BDDFbc2d9e4cF58b7193dc87B5dB1320';
const FEE_ADDRESS = '0x88a31C48BDDFbc2d9e4cF58b7193dc87B5dB1320'

const seaTokenVerify = async () => {
  if (SEA_TOKEN_ADDRESS) {
    await hre.run('verify:verify', {
      address: SEA_TOKEN_ADDRESS,
      constructorArguments: [
        HOLDER_ADDRESS
      ]
    })
  }
};

const closedSeaNFTVerify = async () => {
  if (CLOSEDSEA_NFT_ADDRESS) {
    await hre.run('verify:verify', {
      address: CLOSEDSEA_NFT_ADDRESS,
      constructorArguments: [
        FEE_ADDRESS,
        '1000000000000000',
        '100000000000000000000',
        SEA_TOKEN_ADDRESS
      ]
    })
  }
}

const main = async () => {
  // await seaTokenVerify();
  await closedSeaNFTVerify();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
