// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract KeeperVesting is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable KEEPER;
    event KeeperRedeemed(address redeemer, uint amount);

    struct Term {
        uint percent; // 6 decimals % ( 5000 = 0.5% = 0.005 )
        uint claimed;
    }
    mapping(address => Term) public terms;
    mapping(address => address) public walletChange;
    // uint public totalRedeemable;
    // uint public redeemableLastUpdated;
    uint public totalRedeemed;

    // address public redeemUpdater;


    constructor( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = IERC20(_KEEPER);
        // redeemUpdater = _redeemUpdater;
        // redeemableLastUpdated = block.timestamp;
    }


    // function setRedeemUpdater(address _redeemUpdater) external onlyOwner() {
    //     require( _redeemUpdater != address(0) );
    //     redeemUpdater = _redeemUpdater;
    // }

    // Sets terms for a new wallet
    function setTerms(address _vester, uint _percent ) external onlyOwner() returns ( bool ) {
        terms[_vester].percent = _percent;
        return true;
    }

    // Sets terms for multiple wallets
    function setTermsMultiple(address[] calldata _vesters, uint[] calldata _percents ) external onlyOwner() returns ( bool ) {
        for (uint i=0; i < _vesters.length; i++) {
            terms[_vesters[i]].percent = _percents[i];
        }
        return true;
    }


    // function updateTotalRedeemable() external {
    //     require( msg.sender == redeemUpdater, "Only redeem updater can call." );
    //     uint keeperBalance = KEEPER.balanceOf( address(this) );

    //     uint newRedeemable = keeperBalance.add(totalRedeemed).mul(block.timestamp.sub(redeemableLastUpdated)).div(31536000);
    //     totalRedeemable = totalRedeemable.add(newRedeemable);
    //     if (totalRedeemable > keeperBalance ) {
    //         totalRedeemable = keeperBalance;
    //     }
    //     redeemableLastUpdated = block.timestamp;
    // }

    // Allows wallet to redeem KEEPER
    function redeem( uint _amount ) external returns ( bool ) {
        Term memory info = terms[ msg.sender ];
        require( redeemable( info ) >= _amount, 'Not enough vested' );
        KEEPER.safeTransfer(msg.sender, _amount);
        terms[ msg.sender ].claimed = info.claimed.add( _amount );
        totalRedeemed = totalRedeemed.add(_amount);
        emit KeeperRedeemed(msg.sender, _amount);
        return true;
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange( address _newWallet ) external returns ( bool ) {
        require( terms[ msg.sender ].percent != 0 );
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

    // Amount a wallet can redeem
    function redeemableFor( address _vester ) public view returns (uint) {
        return redeemable( terms[ _vester ]);
    }

    function redeemable( Term memory _info ) internal view returns ( uint ) {
        uint maxRedeemable = KEEPER.balanceOf( address(this) ).add( totalRedeemed );
        if ( maxRedeemable > 1e17 ) {
            maxRedeemable = 1e17;
        }
        uint maxRedeemableUser = maxRedeemable.mul( _info.percent ).div(1e6);
        return maxRedeemableUser.sub(_info.claimed);
    }
}