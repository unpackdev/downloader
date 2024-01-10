// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ICroakens.sol";
import "./ISwampverse.sol";

/**
    @title Creatures contract
    @author https://github.com/kanedaaaa
 */

contract Creatures is ERC721A, ERC721ABurnable, Ownable {
    using Strings for uint256;

    uint256 MAX_SUPPLY = 2400;
    uint256 ERC20_BURN_AMOUNT = 450 * (10**18);
    uint256 ERC721_BURN_AMOUNT = 2;

    string public BEGINNING_URI = "";
    string public ENDING_URI = "";

    address public blackHole = 0x000000000000000000000000000000000000dEaD;

    bool public mintingAllowed = false;

    ICroakens public croakens;
    ISwampverse public swampverse;

    constructor(ICroakens _croakens, ISwampverse _swampverse)
        ERC721A("Swampverse: Creatures", "Creatures")
    {
        croakens = _croakens;
        swampverse = _swampverse;
    }

    /**
        @notice mint a creature in exchange of 2 swampverse token
        and 450 croakens burn

        @param _ids => array of swampverse ids to be burned

        @dev there is no need to check if user has enough balance to burn. 
        if ther is insuficient amount, approve (and transaction) will fail 
        either way so another require check would be redundant
     */
    function mintCreature(uint256[] memory _ids) public {
        require(mintingAllowed, "Creatures.mintCreature: MINTING_NOT_ALLOWED");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Creatures.mintCreature: TOKEN_LIMIT_ERROR");
        require(_ids.length == ERC721_BURN_AMOUNT, "Creatures.mintCreature: WRONG_IDS_LENGTH");
        croakens.approve(blackHole, ERC20_BURN_AMOUNT);

        croakens.burn(msg.sender, ERC20_BURN_AMOUNT);

        for (uint256 x = 0; x < _ids.length; x++) {
           swampverse.safeTransferFrom(msg.sender, blackHole, _ids[x]);
        }
        _safeMint(msg.sender, 1);
    }

    /**
        @param _mode: 
        1 - replace beinning of URI
        2 - replce ending of URI
        anything else - will result in revert()

        @param _new_uri: corresponding value
     */
    function setURI(uint256 _mode, string memory _new_uri) public onlyOwner {
        if (_mode == 1) BEGINNING_URI = _new_uri;
        else if (_mode == 2) ENDING_URI = _new_uri;
        else revert('Creatures.setURI: WRONG_MODE');
    }

    /**
        @param _mode:
        1 - change max_supply 
        2 - change Croakens burn amount
        3 - change swampverse burn amount
        anythign else - will result in revert()

        @param _value: corresponding value
     */
    function setUintInfo(uint256 _mode, uint256 _value) public onlyOwner {
        if (_mode == 1) MAX_SUPPLY = _value;
        else if (_mode == 2) ERC20_BURN_AMOUNT = _value * (10**18);
        else if (_mode == 3) ERC721_BURN_AMOUNT = _value;
        else revert('Creatures.setUintInfo: WRONG_MODE');
    }

    /**
        @notice change burn address

        @param _value => new burn address

        @dev can't set 0x0 due to previous contract implementation
        restrictions from openzeppelin ERC721 contract.
     */
    function changeBurnAddress(address _value) public onlyOwner {
        require(
            _value != address(0),
            "Creatures.changeBurnAddress: zero_address_transfer_is_restricted"
        );
        blackHole = _value;
    }

    /**
        @notice set croakens and swampverse addresses
        
        @param _mode:
        1 - set croakens address
        2 - set swampverse address
        anythign else - will result in revert()
     */
    function setAddresses(uint8 _mode, address _address) public onlyOwner {
        if (_mode == 1) croakens = ICroakens(_address);
        else if (_mode == 2) swampverse = ISwampverse(_address);
        else revert('Creatures.setAddresses: WRONG_MODE');
    }

    /**
        @notice allow minting

        @param _value => true or false
     */
    function toggleMinting(bool _value) public onlyOwner {
        mintingAllowed = _value;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(BEGINNING_URI, tokenId.toString(), ENDING_URI)
            );
    }
}

