
pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./IERC721Receiver.sol";

import "./ec_token.sol";
import "./ec_configuration.sol";
import "./community_interface.sol";


import "./console.sol";


contract pluto_community is ec_configuration, IERC721Receiver {
    using SafeMath for uint256;

    ec_token                    _token;
    address                     constant DEAD_0X = 0x000000000000000000000000000000000000dEaD;

    // delays are 
    uint256 []                  before_presale = [24 hours];

    uint256                     pluto_minted;
    address                     PLUTO_1;


    event CommunityClaimed(uint256 oldPluto);
    event TestMode();

    constructor(ec_token token, address _pluto) {
        _token = token;
        PLUTO_1 = _pluto;
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            before_presale = [30 minutes];
            emit TestMode();
        }
    }


    function _split(uint256 amount) internal { // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = amount * _shares[j] / 1000;
            if (j == _wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            ( sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }


    function burn_active() public view returns (bool) {
        return 
            (block.timestamp >= (_presaleStart - before_presale[0]))
            &&
            (block.timestamp < _presaleStart)
            ;
    }

    function onERC721Received(
        address ,
        address from,
        uint256 tokenId,
        bytes calldata 
    ) external override returns (bytes4) {
        //console.log("here");
        require(msg.sender == PLUTO_1,"Unauthorised sender");
        require(pluto_minted++ < 3333,"Mint Limit Reached");
        require(burn_active(),"Only possible during burn and mint presale");
        
        IERC721(PLUTO_1).transferFrom(address(this),DEAD_0X,tokenId);
        //console.log("token ",address(_token));
        _token.mintCards(1, from);

        return IERC721Receiver.onERC721Received.selector;

    }

}