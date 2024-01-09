// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";
import "./IStaking.sol";


interface IcKEEPER {
    function burnFrom( address account_, uint256 amount_ ) external;
}


contract cKeeperExercise is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable cKEEPER;
    address public immutable KEEPER;
    address public immutable USDC;
    address public immutable treasury;

    address public staking;
    uint private constant CLIFF = 250000 * 10**9;   // Minimum KEEPER supply to exercise
    uint private constant TOUCHDOWN = 5000000 * 10**9;    // Maximum KEEPER supply for percent increase
    uint private constant Y_INCREASE = 35000;    // Increase from CLIFF to TOUCHDOWN is 3.5%. 4 decimals used

    // uint private constant SLOPE = Y_INCREASE.div(TOUCHDOWN.sub(CLIFF));  // m = (y2 - y1) / (x2 - x1)

    struct Term {
        uint initPercent; // 4 decimals ( 5000 = 0.5% )
        uint claimed;
        uint max;
    }
    mapping(address => Term) public terms;
    mapping(address => address) public walletChange;


    constructor( address _cKEEPER, address _KEEPER, address _USDC, address _treasury, address _staking ) {
        require( _cKEEPER != address(0) );
        cKEEPER = _cKEEPER;
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _USDC != address(0) );
        USDC = _USDC;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _staking != address(0) );
        staking = _staking;
    }

    function setStaking( address _staking ) external onlyOwner() {
        require( _staking != address(0) );
        staking = _staking;
    }

    // Sets terms for a new wallet
    function setTerms(address _vester, uint _amountCanClaim, uint _rate ) external onlyOwner() returns ( bool ) {
        terms[_vester].max = _amountCanClaim;
        terms[_vester].initPercent = _rate;
        return true;
    }

    // Sets terms for multiple wallets
    function setTermsMultiple(address[] calldata _vesters, uint[] calldata _amountCanClaims, uint[] calldata _rates ) external onlyOwner() returns ( bool ) {
        for (uint i=0; i < _vesters.length; i++) {
            terms[_vesters[i]].max = _amountCanClaims[i];
            terms[_vesters[i]].initPercent = _rates[i];
        }
        return true;
    }

    // Allows wallet to redeem cKEEPER for KEEPER
    function exercise( uint _amount, bool _stake, bool _wrap ) external returns ( bool ) {
        Term memory info = terms[ msg.sender ];
        require( redeemable( info ) >= _amount, 'Not enough vested' );
        require( info.max.sub( info.claimed ) >= _amount, 'Claimed over max' );

        uint usdcAmount = _amount.div(1e12);
        IERC20( USDC ).safeTransferFrom( msg.sender, address( this ), usdcAmount );
        IcKEEPER( cKEEPER ).burnFrom( msg.sender, _amount );

        IERC20( USDC ).approve( treasury, usdcAmount );
        uint KEEPERToSend = ITreasury( treasury ).deposit( usdcAmount, USDC, 0 );

        terms[ msg.sender ].claimed = info.claimed.add( _amount );

        if ( _stake ) {
            IERC20( KEEPER ).approve( staking, KEEPERToSend );
            IStaking( staking ).stake( KEEPERToSend, msg.sender, _wrap );
        } else {
            IERC20( KEEPER ).safeTransfer( msg.sender, KEEPERToSend );
        }

        return true;
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange( address _newWallet ) external returns ( bool ) {
        require( terms[ msg.sender ].initPercent != 0 );
        walletChange[ msg.sender ] = _newWallet;
        return true;
    }

    // Allows wallet to pull rights from an old address
    function pullWalletChange( address _oldWallet ) external returns ( bool ) {
        require( walletChange[ _oldWallet ] == msg.sender, "wallet did not push" );
        walletChange[ _oldWallet ] = address(0);
        terms[ msg.sender ] = terms[ _oldWallet ];
        delete terms[ _oldWallet ];
        return true;
    }

    // Amount a wallet can redeem based on current supply
    function redeemableFor( address _vester ) public view returns (uint) {
        return redeemable( terms[ _vester ]);
    }

    function redeemable( Term memory _info ) internal view returns ( uint ) {
        if ( _info.initPercent == 0 ) {
            return 0;
        }
        uint keeperSupply = IERC20( KEEPER ).totalSupply();
        if (keeperSupply < CLIFF) {
            return 0;
        } else if (keeperSupply > TOUCHDOWN) {
            keeperSupply = TOUCHDOWN;
        }
        uint percent = Y_INCREASE.mul(keeperSupply.sub(CLIFF)).div(TOUCHDOWN.sub(CLIFF)).add(_info.initPercent);
        return ( keeperSupply.mul( percent ).mul( 1000 ) ).sub( _info.claimed );
    }
}