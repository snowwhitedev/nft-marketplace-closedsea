require('dotenv').config();
const hre = require('hardhat');

const SEA_TOKEN_ADDRESS = '0xDB5236b6797D6ddc9419226A81a0A403B0DA929D';
const HOLDER_ADDRESS = '0xC76e750c31eA0AeF85d53F73782C8d630836047d';

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

const main = async () => {
  await seaTokenVerify();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
