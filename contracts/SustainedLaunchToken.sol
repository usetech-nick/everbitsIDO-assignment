// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILaunchpadFactory.sol";

contract SustainedLaunchToken is ERC20, ERC20Burnable, Ownable {
    ILaunchpadFactory public launchpadFactory;

    uint256 public constant BLOCKS_500 = 500;
    uint256 public constant BLOCKS_1000 = 1000;
    uint256 public constant AVG_BLOCK_TIME = 13;

    uint256 public initialMaxBuyLimit;
    uint256 public maxHolding;
    uint256 public maxHoldingLimit;
    uint256 public taxPercentage;
    uint256 public launchTimestamp;

    address public tokenCreator;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialMaxBuyLimit,
        uint256 _maxHolding,
        uint256 _maxHoldingPeriod,
        uint256 _taxPercentage,
        address _tokenCreator
    ) ERC20(name, symbol) Ownable(msg.sender) {
        launchpadFactory = ILaunchpadFactory(msg.sender);

        tokenCreator = _tokenCreator;
        initialMaxBuyLimit = _initialMaxBuyLimit;
        maxHolding = _maxHolding;
        maxHoldingLimit = block.timestamp + _maxHoldingPeriod;
        taxPercentage = _taxPercentage;

        launchTimestamp = block.timestamp;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // TODO: tax should be on buy/sell, not on all transactions
    function _update(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            balanceOf(recipient) + amount <= getMaxHolding(),
            "Exceeds max holding"
        );
        require(amount <= getMaxBuyLimit(), "Exceeds max buy limit");

        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 transferAmount = amount - taxAmount;

        if (!isWhitelisted(sender) && !isWhitelisted(recipient)) {
            super._update(sender, tokenCreator, taxAmount / 2);
            super._update(
                sender,
                launchpadFactory.getEverbitsTreasury(),
                taxAmount / 2
            );
        }
        super._update(sender, recipient, transferAmount);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return launchpadFactory.isWhitelisted(address(this), _address);
    }

    function getMaxBuyLimit() internal view returns (uint256) {
        if (block.timestamp < launchTimestamp + BLOCKS_500 * AVG_BLOCK_TIME) {
            return initialMaxBuyLimit / 2;
        } else if (
            block.timestamp < launchTimestamp + BLOCKS_1000 * AVG_BLOCK_TIME
        ) {
            return initialMaxBuyLimit;
        } else {
            return type(uint256).max;
        }
    }

    function getMaxHolding() internal view returns (uint256) {
        if (block.timestamp < maxHoldingLimit) {
            return maxHolding;
        } else {
            return type(uint256).max;
        }
    }
}
