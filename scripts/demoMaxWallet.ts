import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  console.log("Signer:", signer.address);

  // ✅ Reuse deployed LaunchpadFactory
  const FACTORY_ADDRESS = "0xDf98886FDc77c9DE4B4559eE2af542E73f28B08E";

  const factory = await ethers.getContractAt(
    "LaunchpadFactory",
    FACTORY_ADDRESS
  );

  const block = await ethers.provider.getBlock("latest");
  const now = block.timestamp;

  // ✅ Small numbers for Sepolia demo
  const params = {
    name: "MiniEverbits",
    symbol: "mEVB",
    totalSupply: ethers.utils.parseEther("1000"),
    idoSupply: ethers.utils.parseEther("100"),
    liquidityPercentage: 5000, // 50%
    softCap: ethers.utils.parseEther("0.002"),
    hardCap: ethers.utils.parseEther("0.01"),
    startTimestamp: now - 120,
    endTimestamp: now + 3600,
    liquidityLockDuration: 3600,
    maxTokensPerWallet: ethers.utils.parseEther("10"),
  };

  console.log("Creating Mini IDO...");

  const tx = await factory.createStandardIDO(params, {
    gasLimit: 3_000_000,
  });

  const receipt = await tx.wait();

  const event = receipt.events?.find(
    (e: any) => e.event === "StandardIDOCreated"
  );

  if (!event) {
    throw new Error("StandardIDOCreated event not found");
  }

  const idoAddress = event.args._ido;
  console.log("Mini IDO deployed at:", idoAddress);

  const ido = await ethers.getContractAt("EverbitsIDO", idoAddress);

  // ✅ First contribution (allowed)
  console.log("Sending 0.001 ETH (should succeed)");
  const tx1 = await ido.contribute({
    value: ethers.utils.parseEther("0.001"),
    gasLimit: 200_000,
  });
  await tx1.wait();
  console.log("✅ Contribution accepted");

  // ❌ Second contribution (should revert)
  console.log("Simulating failing contribution (callStatic)");

try {
  await ido.callStatic.contribute({
    value: ethers.utils.parseEther("0.0011"),
  });
} catch (err: any) {
  console.log("Revert message (static call):", err.reason);
}

//   console.log("Sending 0.0011 ETH (should revert)");

//   try {
//     await ido.contribute({
//       value: ethers.utils.parseEther("0.0011"),
//       gasLimit: 200_000,
//     });
//   } catch (err: any) {
//   console.log("✅ Reverted as expected");
//   if (err.error?.message) {
//     console.log("Revert message:", err.error.message);
//   } else if (err.reason) {
//     console.log("Revert reason:", err.reason);
//   } else {
//     console.log("Raw error:", err.message);
//   }
// }


  console.log("🎯 Demo complete");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
