//SPDX-License-Identifier: MIT

/*........................................................................................
..........................................................................................
.........................................::--:............................................
......................................:=+++++++=.................:-==-:...................
.....................................=++++++++++=..............-++++++++:.................
...................................:=++++++++++++............:=++++++++++.................
..................................:+++=--===+=++=...........-====--+=++++-................
.................................:+++-    ======:.........:====:   -====+-................
................................:===:     =====-.........:====.    :=====:................
...............................:===-     :=====.........-====.     =====-.................
...............................====     .=====.........-====.     -=====..................
..............................-===.    .=====.........-====.     -=====...................
..............................===-    .=====.........-====.     -=====....................
.............................-===     ====-.........:===-     .=====-.....................
.............................===:    -===-.........:===-     -====-.......................
............................:===    :===-.........:===:    .====-:........................
............................-===    ====..::::::.:===:    -===-:..........................
............................===:   :================.   .===-:............................
...........................:===. :-================.   -===:..............................
...........................:=======================:..====++=:............................
...........................-==============================++++=...........................
..........................-================================+++++:.........................
........................:================:....:=============+++++-........................
.......................:.:-.============  .+**=.-===========++++++:.......................
........................-##=.==========: .######.===========+++++++.......................
......................- *### ==========. -######=:==========+++++++-......................
......................- ####.==========  =######*:==========+++++++-......................
.....................:- #### ==:.:=====  =######*:==========+++++++-......................
.....................:- ###* =.....====  =######+:=========+++++++=:......................
......................- *##= . ==:  :==. =######=-=========++++=-.........................
.....................   :*+    .-     .  .#####*:==========--:............................
.....................        ::::::::      ---: .......     ..............................
.....................                                       ..............................
......................                                    ................................
.........................                               ..................................
...............................                     ......................................
....................................:=+=:::::::=##+-:.....................................
...................................*###%%#***#%%%%##*.....................................
...................................################*......................................
................................. :################-.....=#-..............................
.............................:*:.:=###############+::....###+.............................
............................:*#--:-==---:-:--:--==-:.:--+####*:...........................
............................*##-: .. ... . .. . .  ::::-######*...........................
...........................+###:. .. .. .. .. .. ......:#######+..........................
..........................-####: ... .. .. .. .. ... ..=########=.........................
...................................................................Author: @ryanycwEth, C& 
...............................................................Head of Project: @jstin.eth
.....................................................................PR Manager: @Swi Chen
...................................................................Collab Manager: @Ken Ke
............................................................Community Manager: @Hazel Tsai
...............................................................Web Developer: @Mosano Yang
...........................................................Art & Dev Manager: @javic.eth*/

pragma solidity 0.8.4;

import "./IRAIbbitHoleTicket.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./BitMaps.sol";
import "./ECDSA.sol";
import "./ERC721Burnable.sol";
import "./ERC1155.sol";
import "./ERC2981.sol";

error InvalidInput();
error InvalidTime();
error InvalidAddress();
error InvalidSignature();
error ExceedAmount();
error AddressUnset();
error MintInfoUnset();
error Unauthorized();

contract RAIbbitHoleTicketStorage {
    uint256 public constant tokenId = 0;
    uint256 public constant maxTicketAmount = 3000;
    address public constant rugPullFrensAddress = address(0xc9E3Ca32CAaA6ee67476C5d35d4B8ec64F58D4Ad);
    string public constant name = "RAIbbitHoleTicket";
    string public constant symbol = "RAIHT";

    uint256 public totalSupply;
    mapping(address => bool) public minted;

    /// Set with #setPublicMintPhase
    uint256 public mintPublicStartTime;
    uint256 public mintPublicEndTime;
    /// Set with #setAuthorized
    mapping(address => bool) public isAuthorized;
}

contract RAIbbitHoleTicket is 
    IRAIbbitHoleTicket,
    RAIbbitHoleTicketStorage,
    ReentrancyGuard,
    Ownable,
    ERC1155,
    ERC2981 {

    using BitMaps for BitMaps.BitMap;

    constructor(
        uint96 _royaltyFee,
        string memory _tokenURI
    )
        ERC1155(_tokenURI)
    {
        isAuthorized[owner()] = true;

        _setDefaultRoyalty(owner(), _royaltyFee);
    }

      ///////////////
     // Modifiers //
    ///////////////

    modifier onlyAuthorized() {
        // If the address is in the authorizer address array
        if (!isAuthorized[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier mintPublicActive() {
        // If it's not yet or after the whitelist mint time
        if (block.timestamp <= mintPublicStartTime || block.timestamp >= mintPublicEndTime) {
            revert InvalidTime();
        }
        _;
    }

    /** 
     * @dev Override same interface function in different inheritance.
     * @param _interfaceId Id of an interface to check whether the contract support
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

      //////////////////////////////
     // User Execution Functions //
    //////////////////////////////

    /** 
     * @dev Mint designated quantity of tickets to an address as owner
     * @param _to Address to transfer the tickets
     * @param _quantity Designated quantity of tickets
     */
    function giveawayTicket(
        address _to, 
        uint256 _quantity
    ) 
        external
        override
        onlyAuthorized
    {
        _mint(_to, tokenId, _quantity, "");
    }

    /** 
     * @dev User can burn Rug Pull Frens and mint ticket
     * @param _burnId TokenId of RPF that callers want to burn
     */
    function mintTicket(uint256 _burnId) 
        external
        override
        nonReentrant
        mintPublicActive
    {
        // Every address can only mint once
        if(minted[msg.sender]) {
            revert InvalidAddress();
        }

        minted[msg.sender] = true;
        ERC721Burnable(rugPullFrensAddress).burn(_burnId);

        _mint(msg.sender, tokenId, 1, "");
    }

    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )   
        internal
        override
    {
        totalSupply += _amount;

        // Check if the mint amount is zero, revert to save gas
        if (_amount == 0) {
            revert InvalidInput();
        }

        // Check if the mint amount exceeds the maximum ticket supply
        if (totalSupply > maxTicketAmount) {
            revert ExceedAmount();
        }

        super._mint(_to, _id, _amount, _data);
    }

      /////////////////////////
     // Set Phase Functions //
    /////////////////////////

    /** 
     * @dev Set the mint time for user to burn Rug Pull Frens
     * @param _startTime After this timestamp the mint phase will be enabled
     * @param _endTime After this timestamp the mint phase will be disabled
     */
    function setPublicMintPhase(
        uint256 _startTime,
        uint256 _endTime
    ) 
        external
        override
        onlyAuthorized
    {
        // If we set the start time before end time
        if (_startTime > _endTime) {
            revert InvalidInput();
        }
        
        mintPublicStartTime = _startTime;
        mintPublicEndTime = _endTime;

        emit PhaseSet(_startTime, _endTime, "Public");
    }

      /////////////////////////
     // Set Roles Functions //
    /////////////////////////

    /** 
     * @dev Set the status of whether an address is authorized
     * @param _authorizer Address to change its authorized status
     * @param _authorizedStatus New status to assign to the authorizer
     */
    function setAuthorizer(
        address _authorizer, 
        bool _authorizedStatus
    )
        external
        override
        onlyOwner
    {
        isAuthorized[_authorizer] = _authorizedStatus;

        emit AuthorizerChange(_authorizer, _authorizedStatus);
    }

      //////////////////////////
     // Set Params Functions //
    //////////////////////////

    /** 
     * @dev Set the royalties information for platforms that support ERC2981, LooksRare & X2Y2
     * @param _receiver Address that should receive royalties
     * @param _feeNumerator Amount of royalties that collection creator wants to receive
     */
    function setDefaultRoyalty(
        address _receiver, 
        uint96 _feeNumerator
    )
        external
        override
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /** 
     * @dev Set the royalties information for platforms that support ERC2981, LooksRare & X2Y2
     * @param _receiver Address that should receive royalties
     * @param _feeNumerator Amount of royalties that collection creator wants to receive
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) 
        external 
        override
        onlyOwner 
    {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /** 
     * @dev Set the URI for tokenURI, which returns the metadata of token
     * @param _baseURI New URI that caller wants to set as tokenURI
     */
    function setBaseURI(string memory _baseURI)
        external
        override
        onlyOwner
    {
        _setURI(_baseURI);

        emit BaseURISet(_baseURI);
    }
}