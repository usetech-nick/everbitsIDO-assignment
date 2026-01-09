import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  console.log("Signer:", signer.address);

  const UNISWAP_V2_ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const UNISWAP_V2_FACTORY = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

  const Factory = await ethers.getContractFactory("LaunchpadFactory");

  // 👇 Build deploy tx manually
  const deployTx = Factory.getDeployTransaction(
    UNISWAP_V2_ROUTER,
    UNISWAP_V2_FACTORY,
    signer.address
  );

deployTx.gasLimit = 6_000_000;
deployTx.gasPrice = ethers.utils.parseUnits("15", "gwei");
  console.log("Sending raw deploy tx...");

  const tx = await signer.sendTransaction(deployTx);

  console.log("TX HASH:", tx.hash);

  const receipt = await tx.wait(1);

  console.log("Contract deployed at:", receipt.contractAddress);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
