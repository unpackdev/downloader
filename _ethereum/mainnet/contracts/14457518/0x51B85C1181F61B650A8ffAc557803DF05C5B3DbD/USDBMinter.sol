// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20PresetMinterPauser.sol";

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IBurnable {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

contract USDBMinter is Ownable, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public fhmAddress;
    address public usdbAddress;
    address public fhudAddress;

    address public fhmLpAddress;
    uint256 public decimals;
    bool public doDiv;

    mapping(address => bool) mintByFhudWhitelist;
    bool mintByFhudWhitelistEnabled;

    event USDBMintedFromFHM(
        uint256 timestamp,
        address minter,
        uint256 fhmAmountBurnt,
        uint256 usdbAmountMinted
    );

    event USDBMintedFromFHUD(
        uint256 timestamp,
        address minter,
        uint256 fhudAmountBurnt,
        uint256 usdbAmountMinted
    );

    constructor() {
        mintByFhudWhitelistEnabled = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * 2 decimals
     */
    function getMarketPrice() public view returns (uint256) {
        ( uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair( fhmLpAddress ).getReserves();
        if ( IUniswapV2Pair( fhmLpAddress ).token0() == fhmAddress ) {
            if (doDiv) return reserve1.div(reserve0).div( 10**decimals );
            else return reserve1.mul( 10**decimals ).div(reserve0);
        } else {
            if (doDiv) return reserve0.div(reserve1).div( 10**decimals );
            else return reserve0.mul( 10**decimals ).div(reserve1);
        }
    }

    function getFhmAmount(uint256 _stableCoinAmount, uint256 _marketPrice) public view returns (uint256) {
        return _stableCoinAmount.div(_marketPrice.div(10**2)).div(10**9);
    }

    /**
     * stableCoinAmount - 18 decimals
     * minimalTokenPrice - 2 decimals
     */
    // 10,000 usd / 100.00 usd/fhm
    // 10,000.000,000,000,000,000,000 / 100.00
    function mintFromFHM(uint256 _stableCoinAmount, uint256 _minimalTokenPrice) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINTER_ROLE_MISSING");

        uint256 marketPrice = getMarketPrice();
        require(marketPrice >= _minimalTokenPrice, "SLIPPAGE_NOT_MET");

        uint256 fhmAmount = getFhmAmount(_stableCoinAmount, marketPrice);
        IBurnable(fhmAddress).burnFrom(msg.sender, fhmAmount);
        IMintable(usdbAddress).mint(msg.sender, _stableCoinAmount);

        emit USDBMintedFromFHM(block.timestamp, msg.sender, fhmAmount, _stableCoinAmount);
    }

    function mintFromFHUD(uint _fhudAmount) external {
        if (mintByFhudWhitelistEnabled) {
            require(mintByFhudWhitelist[msg.sender], "MISSING_IN_WHITELIST");
        }
        IBurnable(fhudAddress).burnFrom(msg.sender, _fhudAmount);
        IMintable(usdbAddress).mint(msg.sender, _fhudAmount);

        emit USDBMintedFromFHUD(block.timestamp, msg.sender, _fhudAmount, _fhudAmount);
    }

    function setFhmAddress(address _fhmAddress) external virtual onlyOwner {
        fhmAddress = _fhmAddress;
    }

    function setUsdbAddress(address _usdbAddress) external virtual onlyOwner {
        usdbAddress = _usdbAddress;
    }

    function setFhudAddress(address _fhudAddress) external virtual onlyOwner {
        fhudAddress = _fhudAddress;
    }

    function setMintByFhudEnabled(bool _mintByFhudWhitelistEnabled) external virtual onlyOwner {
        mintByFhudWhitelistEnabled = _mintByFhudWhitelistEnabled;
    }

    function modifyWhitelist(address user, bool add) external onlyOwner {
        if (add) {
            require(!mintByFhudWhitelist[user], "ALREADY_IN_WHITELIST");
            mintByFhudWhitelist[user] = true;
        } else {
            require(mintByFhudWhitelist[user], "NOT_IN_WHITELIST");
            delete mintByFhudWhitelist[user];
        }
    }

    function setFhmLpAddress(address _fhmLpAddress, uint256 _decimals, bool _doDiv) external virtual onlyOwner {
        fhmLpAddress = _fhmLpAddress;
        decimals = _decimals;
        doDiv = _doDiv;
    }

    function recoverTokens(address _token) external virtual onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function recoverEth() external virtual onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice grants minter role to given _account
    /// @param _account minter contract
    function grantRoleMinter(address _account) external {
        grantRole(MINTER_ROLE, _account);
    }

    /// @notice revoke minter role to given _account
    /// @param _account minter contract
    function revokeRoleMinter(address _account) external {
        revokeRole(MINTER_ROLE, _account);
    }

}
