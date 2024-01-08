// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";

import "./ISinglePlus.sol";
import "./ICompositePlus.sol";

/**
 * @dev Zap for Badger BTC.
 */
contract BadgerBTCZap is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Minted(address indexed account, address[] tokens, uint256[] amounts, uint256 mintAmount);
    event Redeemed(address indexed account, address[] tokens, uint256[] amounts, uint256 redeemAmount);

    address public constant BADGER_RENCRV = address(0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545);
    address public constant BADGER_RENCRV_PLUS = address(0x87BAA3E048528d21302Fb15acd09a4e5cB5098cB);
    address public constant BADGER_SBTCCRV = address(0xd04c48A53c111300aD41190D63681ed3dAd998eC);
    address public constant BADGER_SBTCCRV_PLUS = address(0xb346d6Fcea1F328b64cF5F1Fe5108841607A7Fef);
    address public constant BADGER_TBTCCRV = address(0xb9D076fDe463dbc9f915E5392F807315Bf940334);
    address public constant BADGER_TBTCCRV_PLUS = address(0x25d8293E1d6209d6fa21983f5E46ee6CD36d7196);
    address public constant BADGER_HRENCRV = address(0xAf5A1DECfa95BAF63E0084a35c62592B774A2A87);
    address public constant BADGER_HRENCRV_PLUS = address(0xd929f4d3ACBD19107BC416685e7f6559dC07F3F5);
    address public constant BADGER_BTC_PLUS = address(0x7cD7a5B7Ebe9F852bD1E87117b36504D22d9385B);

    address public governance;
    
    /**
     * @dev Initializes Badger BTC Zap.
     */
    function initialize() public initializer {
        governance = msg.sender;

        IERC20Upgradeable(BADGER_RENCRV).safeApprove(BADGER_RENCRV_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_SBTCCRV).safeApprove(BADGER_SBTCCRV_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_TBTCCRV).safeApprove(BADGER_TBTCCRV_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_HRENCRV).safeApprove(BADGER_HRENCRV_PLUS, uint256(int256(-1)));

        IERC20Upgradeable(BADGER_RENCRV_PLUS).safeApprove(BADGER_BTC_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_SBTCCRV_PLUS).safeApprove(BADGER_BTC_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_TBTCCRV_PLUS).safeApprove(BADGER_BTC_PLUS, uint256(int256(-1)));
        IERC20Upgradeable(BADGER_HRENCRV_PLUS).safeApprove(BADGER_BTC_PLUS, uint256(int256(-1)));
    }

    /**
     * @dev Returns the amount of BagerBTC+ minted.
     * @param _singles Single pluses used to mint BadgerBTC
     * @param _lpAmounts Amount of LP token (not single plus) used to mint BadgerBTC+
     */
    function getMintAmount(address[] memory _singles, uint256[] memory _lpAmounts) public view returns (uint256) {
        require(_singles.length == _lpAmounts.length, "input mismatch");
        
        uint256[] memory _amounts = new uint256[](_singles.length);
        for (uint256 i = 0; i < _singles.length; i++) {
            if (_lpAmounts[i] == 0) continue;
            _amounts[i] = ISinglePlus(_singles[i]).getMintAmount(_lpAmounts[i]);
        }

        return ICompositePlus(BADGER_BTC_PLUS).getMintAmount(_singles, _amounts);
    }

    /**
     * @dev Mints BadgerBTC+.
     * @param _singles Single pluses used to mint BadgerBTC
     * @param _lpAmounts Amount of LP token (not single plus) used to mint BadgerBTC+
     */
    function mint(address[] memory _singles, uint256[] memory _lpAmounts) public {
        require(_singles.length == _lpAmounts.length, "input mismatch");
        
        address[] memory _lps = new address[](_singles.length);
        uint256[] memory _amounts = new uint256[](_singles.length);
        for (uint256 i = 0; i < _singles.length; i++) {
            if (_lpAmounts[i] == 0) continue;

            // Transfers LP token in
            _lps[i] = ISinglePlus(_singles[i]).token();
            IERC20Upgradeable(_lps[i]).safeTransferFrom(msg.sender, address(this), _lpAmounts[i]);
            // Mints Single+
            ISinglePlus(_singles[i]).mint(_lpAmounts[i]);

            _amounts[i] = IERC20Upgradeable(_singles[i]).balanceOf(address(this));
        }

        ICompositePlus(BADGER_BTC_PLUS).mint(_singles, _amounts);
        uint256 _badgerBTCPlus = IERC20Upgradeable(BADGER_BTC_PLUS).balanceOf(address(this));
        IERC20Upgradeable(BADGER_BTC_PLUS).safeTransfer(msg.sender, _badgerBTCPlus);

        emit Minted(msg.sender, _lps, _lpAmounts, _badgerBTCPlus);
    }

    /**
     * @dev Returns the amount of tokens received in redeeming BadgerBTC+.
     * @param _amount Amount of BadgerBTC+ to redeem.
     */
    function getRedeemAmount(uint256 _amount) public view returns (address[] memory, uint256[] memory, uint256) {
        (address[] memory _singles, uint256[] memory _amounts,,) = ICompositePlus(BADGER_BTC_PLUS).getRedeemAmount(_amount);

        address[] memory _lps = new address[](_singles.length);
        uint256[] memory _lpAmounts = new uint256[](_singles.length);

        for (uint256 i = 0; i < _singles.length; i++) {
            _lps[i] = ISinglePlus(_singles[i]).token();
            (_lpAmounts[i],) = ISinglePlus(_singles[i]).getRedeemAmount(_amounts[i]);
        }

        // Compute the amount of BadgerBTC+ that could be mited with the returned LPs.
        // The difference can be seen as fees.
        uint256 _mintAmount = getMintAmount(_singles, _lpAmounts);

        return (_lps, _lpAmounts, _amount.sub(_mintAmount));
    }

    /**
     * @dev Redeems BadgerBTC+.
     * @param _amount Amount of BadgerBTC+ to redeem.
     */
    function redeem(uint256 _amount) public {
        // Transfers BadgerBTC+ in
        IERC20Upgradeable(BADGER_BTC_PLUS).safeTransferFrom(msg.sender, address(this), _amount);
        // Redeems BadgerBTC+ to single+
        ICompositePlus(BADGER_BTC_PLUS).redeem(_amount);

        address[] memory _singles = ICompositePlus(BADGER_BTC_PLUS).tokenList();
        address[] memory _lps = new address[](_singles.length);
        uint256[] memory _lpAmounts = new uint256[](_singles.length);

        for (uint256 i = 0; i < _singles.length; i++) {
            _lps[i] = ISinglePlus(_singles[i]).token();
            uint256 _balance = IERC20Upgradeable(_singles[i]).balanceOf(address(this));
            ISinglePlus(_singles[i]).redeem(_balance);

            _lpAmounts[i] = IERC20Upgradeable(_lps[i]).balanceOf(address(this));
            // Transfers the LP tokens out
            IERC20Upgradeable(_lps[i]).safeTransfer(msg.sender, _lpAmounts[i]);  
        }

        emit Redeemed(msg.sender, _lps, _lpAmounts, _amount);
    }

    /**
     * @dev Used to salvage any ETH deposited to BTC+ contract by mistake. Only governance can salvage ETH.
     * The salvaged ETH is transferred to governance for futher operation.
     */
    function salvage() external {
        require(msg.sender == governance, "not governance");

        uint256 _amount = address(this).balance;
        address payable _target = payable(governance);
        (bool _success, ) = _target.call{value: _amount}(new bytes(0));
        require(_success, 'ETH salvage failed');
    }

    /**
     * @dev Used to salvage any token deposited to plus contract by mistake. Only governances can salvage token.
     * The salvaged token is transferred to governance for futhuer operation.
     * @param _token Address of the token to salvage.
     */
    function salvageToken(address _token) external {
        require(msg.sender == governance, "not governance");

        IERC20Upgradeable _target = IERC20Upgradeable(_token);
        _target.safeTransfer(governance, _target.balanceOf(address(this)));
    }
}