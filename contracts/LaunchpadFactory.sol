// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./EverbitsToken.sol";
import "./SustainedLaunchToken.sol";
import "./EverbitsIDO.sol";
import "./interfaces/IEverbitsToken.sol";
import "./interfaces/ISustainedLaunchToken.sol";
import "./interfaces/ILaunchpadFactory.sol";

contract LaunchpadFactory is Ownable, ILaunchpadFactory {
    event sustainedLaunchRequested(uint256 _id);
    event sustainedLaunchExecuted(uint256 _id, address _token);
    event StandardIDOCreated(address _ido);

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;

    uint256 public sustainedLaunchCount;

    address public everbitsTreasury;

    mapping(uint256 => SustainedLaunch) public sustainedLaunches;

    /**
     * @notice Mapping of token to whitelisted addresses
     */
    mapping(address => mapping(address => bool)) public whitelist;

    constructor(
        address _uinswapV2Router,
        address _uinswapV2Factory,
        address _everbitsTreasury
    ) Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(_uinswapV2Router);
        uniswapV2Factory = IUniswapV2Factory(_uinswapV2Factory);
        everbitsTreasury = _everbitsTreasury;
    }

    function createSustainedLaunch(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply
    ) external {
        sustainedLaunches[sustainedLaunchCount] = SustainedLaunch({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            owner: msg.sender,
            launched: false
        });
        sustainedLaunchCount++;

        emit sustainedLaunchRequested(sustainedLaunchCount - 1);
    }

    function executSsustainedLaunch(
        uint256 id,
        uint256 _initialMaxBuyLimit,
        uint256 _maxHolding,
        uint256 _maxHoldingPeriod,
        uint256 _taxPercentage
    ) external payable onlyOwner {
        SustainedLaunch memory launch = sustainedLaunches[id];

        // Create token and mint the total supply
        SustainedLaunchToken token = new SustainedLaunchToken(
            launch.name,
            launch.symbol,
            _initialMaxBuyLimit,
            _maxHolding,
            _maxHoldingPeriod,
            _taxPercentage,
            launch.owner
        );

        whitelist[address(token)][everbitsTreasury] = true;
        whitelist[address(token)][address(this)] = true;

        // whitelist[address(token)][address(uniswapV2Router)] = true;
        // address lp = uniswapV2Factory.createPair(
        //     address(token),
        //     uniswapV2Router.WETH()
        // );
        // whitelist[address(token)][lp] = true;

        token.mint(address(this), launch.totalSupply);

        // Launch the token on UniSwap
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(token),
            launch.totalSupply,
            0,
            0,
            address(this),
            block.timestamp
        );

        sustainedLaunches[id].launched = true;

        emit sustainedLaunchExecuted(id, address(token));
    }

    function createStandardIDO(StandardIDOParams calldata params) external {
        EverbitsIDO ido = new EverbitsIDO(
            address(uniswapV2Router),
            msg.sender,
            params
        );

        emit StandardIDOCreated(address(ido));
    }

    function getEverbitsTreasury() external view override returns (address) {
        return everbitsTreasury;
    }

    function setEverbitsTreasury(address _everbitsTreasury) external onlyOwner {
        everbitsTreasury = _everbitsTreasury;
    }

    function isWhitelisted(
        address _token,
        address _address
    ) external view returns (bool) {
        return whitelist[_token][_address];
    }
}
