// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**************************************************************\
 * TokenFacetLib authored by Bling Artist Lab
 * Version 0.3.0
 * 
 * This library is designed to work in conjunction with
 * TokenFacet - it facilitates diamond storage and shared
 * functionality associated with TokenFacet.
/**************************************************************/

import "./ERC721AStorage.sol";

library TokenFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    string internal constant URI_TAG = '<URI>';
    string internal constant EXT_TAG = '<EXT>';
    string internal constant DAY_TAG = '<DAY>';
    string internal constant TOKEN_TAG = '<TOKEN>';
    string internal constant CITY_TAG = '<CITY>';
    string internal constant FORGE_TAG = '<FORGE>';

    enum PriceType { Allowlist, Public }
    enum WalletCapType { Allowlist, Public }


    struct state {
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 revealTimeStamp;
        uint256 globalRandom;
        uint256 unitDuration;

        string preRevealURI;
        string postRevealURI;
        string baseURI;
        bool burnStatus;

        uint256[] breakPoints;
        uint256[] price;
        uint256[] day;
        string[] city;
        string[] image;

        mapping (uint256 => uint256) forged;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
     * @dev generate random number
     * @param randomizer another factor to introduce randomness other than block factors
     * @param max upper cap of the random number
     * @return random number
     */
    function random(uint256 randomizer, uint256 max) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    getState().globalRandom, randomizer, max
                )
            )
        ) % max;
    }

    /**
     * @dev get city for given day
     * @param day day number whose city has to be found
     * @return name of the city
     * @return remaining days
     */
    function getCity(uint256 day) internal view returns (string memory, uint256) {
        state storage s = getState();
        for(uint256 i; i < s.day.length;) {
            if(i != 0) {
                if(s.day[i - 1] < day  && day <= s.day[i]) {
                    return (s.city[i], day - s.day[i - 1]);
                }
            }
            else {
                if(day <= s.day[i]) {
                    return (s.city[i], day);
                }
            }
            unchecked {
                i++;
            }
        }
        return ("", 0);
    }
    /**
     * compare given string and return whether they are same or not
     * @param a first value to compare
     * @param b second value to compare
     * @return true if both are same
     */
    function checkTag(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /**
     * check if given tokenId is forget or not
     * @param tokenId token for which to check
     * @return bool is given tokenId is forged
     */
    function isForged(uint256 tokenId) internal view returns (bool) {
        return getState().forged[tokenId] != 0;
    }
     /**
      * @dev initialize the image array
      */
    function initImage() internal {
        string[] storage s = TokenFacetLib.getState().image;

        s.push('data:application/json;utf8,{"name":"Moments #');
        s.push(TOKEN_TAG);
        s.push('","created_by":"Noelz","description":"Different Photos everyday","image":"');
        s.push(URI_TAG);
        s.push(EXT_TAG);
        s.push('","image_url":"');
        s.push(URI_TAG);
        s.push(EXT_TAG);
        s.push('","image_details":{"width":2160,"height":2160,"format":"JPEG"},"attributes": [{"trait_type":"City","value":"');
        s.push(CITY_TAG);
        s.push('"},{"trait_type":"Day Number","value":"');
        s.push(DAY_TAG);
        s.push('"},{"trait_type":"Forged","value":"');
        s.push(FORGE_TAG);
        s.push('"}]}');
    }

    /**
     * @dev Used to generate metadata for the given day
     * @param day day whose metadata has to be generated
     */
    function generateMetadata(uint256 day, uint256 tokenId) internal view returns (string memory) {
        bytes memory byteString;
        string[] memory image = TokenFacetLib.getState().image;
        uint256 length = image.length;
        (string memory city, uint256 currentDay) = getCity(day);
        uint256 endDay = getState().breakPoints[2];

        for(uint256 i; i < length;) {
            if (checkTag(image[i], URI_TAG)) {
                if(day == 0) {
                    byteString = abi.encodePacked(byteString, getState().preRevealURI);
                }
                else if(day == endDay) {
                    byteString = abi.encodePacked(byteString, getState().postRevealURI);
                }
                else {
                    byteString = abi.encodePacked(byteString, getState().baseURI);
                }
            }
            else if (checkTag(image[i], EXT_TAG)) {
                if(!(day == 0 || day == endDay)) {
                    byteString = abi.encodePacked(byteString, string(abi.encodePacked(city, " ", _toString(currentDay), ".jpg")));
                }
            }
            else if (checkTag(image[i], DAY_TAG)) {
                if(day != 366) {
                    byteString = abi.encodePacked(byteString, _toString(day));
                }
                else {
                    byteString = abi.encodePacked(byteString, "Promised");
                }
            }
            else if (checkTag(image[i], CITY_TAG)) {
               byteString = abi.encodePacked(byteString, city);
            }
            else if (checkTag(image[i], FORGE_TAG)) {
                if(isForged(tokenId)) {
                    byteString = abi.encodePacked(byteString, "true");
                }
                else {
                    byteString = abi.encodePacked(byteString, "false");
                }
            }
            else if (checkTag(image[i], TOKEN_TAG)) {
                byteString = abi.encodePacked(byteString, _toString(tokenId));
            }
            else {
                byteString = abi.encodePacked(byteString, image[i]);
            }
            unchecked {
                i++;
            }
        }
        return string(byteString);
    }
 
     /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

/**************************************************************\
 * TokenFacet authored by Bling Artist Lab
 * Version 0.6.0
 * 
 * This facet contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Bling Artist Lab
/**************************************************************/

import "./GlobalState.sol";
import "./AllowlistFacet.sol";

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";

contract TokenFacet is ERC721AUpgradeable, ERC721AQueryableUpgradeable {

    // MODIFIERS //

    /**
     * @dev modifier to restrict
     *      function to admins
     */
    modifier onlyAdmins {
        GlobalState.requireCallerIsAdmin();
        _;
    }

    /**
     * @dev modifier to restrict function
     *      execution based on boolean
     */
    modifier contractNotPause {
        GlobalState.requireContractIsNotPaused();
        _;
    }

    // VARIABLE GETTERS //
    
    /**
     * @dev Getter function for breakpoints variable
     */
    function getBreakPoints() external view returns (uint256[] memory) {
        return TokenFacetLib.getState().breakPoints;
    }
    /**
     * @dev Getter function for image variable
     */
    function getImage() external view returns (string[] memory) {
        return TokenFacetLib.getState().image;
    }
    /**
     * @dev return city for given day
     * @param day day number whose city is requested
     */
    function getDayToCity(uint256 day) external view returns (string memory) {
        (string memory city,) = TokenFacetLib.getCity(day);
        return city;
    }

    /**
     * @dev Getter function for startTimeStamp
     */
    function startTimeStamp() external view returns (uint256) {
        return TokenFacetLib.getState().startTimeStamp;
    }

    /**
     * @dev Getter function for endTimeStamp
     */
    function endTimeStamp() external view returns (uint256) {
        return TokenFacetLib.getState().endTimeStamp;
    }

    /**
     * @dev Getter function for revealTimeStamp
     */
    function revealTimeStamp() external view returns (uint256) {
        return TokenFacetLib.getState().revealTimeStamp;
    }

    /**
     * @dev Getter function for allowlist price
     */
    function priceAl() external view returns (uint256) {
        return TokenFacetLib.getState().price[uint256(TokenFacetLib.PriceType.Allowlist)];
    }

    /**
     * @dev Getter function for public price
     */
    function price() external view returns (uint256) {
        return TokenFacetLib.getState().price[uint256(TokenFacetLib.PriceType.Public)];
    }

    /**
     * @dev Getter function for  unitDuration
     */
    function unitDuration() external view returns (uint256) {
        return TokenFacetLib.getState().unitDuration;
    }
    /**
     * @dev Getter function for preRevealURI
     */
    function preRevealURI() external view returns (string memory) {
        return TokenFacetLib.getState().preRevealURI;
    }

    /**
     * @dev Getter function for postRevealURI
     */
    function postRevealURI() external view returns (string memory) {
        return TokenFacetLib.getState().postRevealURI;
    }

    /**
     * @dev Getter function for burn status of tokens
     */
    function burnStatus() external view returns (bool) {
        return TokenFacetLib.getState().burnStatus;
    }

    /**
     * @dev returns true if sale is open, otherwise false
     */
    function isSaleOpen() public view returns (bool) {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        if(s.startTimeStamp == 0) return false;
        else {
            if(s.endTimeStamp == 0) {
                return block.timestamp >= s.startTimeStamp;
            }
            else {
                return
                    block.timestamp >= s.startTimeStamp &&
                    block.timestamp < s.endTimeStamp;
            }
        }
    }

    /**
     * @dev checks if given tokenId is forged or not
     * @param tokenId token for which forged status has to be checked
     */
    function isForged(uint256 tokenId) external view returns (bool) {
        return TokenFacetLib.isForged(tokenId);
    }

    // SETUP & ADMIN FUNCTIONS //

    /**
     * @dev burn multiple token at once
     * @param tokenIds array of tokens that are to be burned
     */
    function burnMany(uint256[] memory tokenIds) external onlyAdmins {
        for(uint256 i; i < tokenIds.length;) {
            _burn(tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev admin only function to update
     *      break points
     * @param breakPoints breakpoints for generating metadata
     */
    function setBreakPoints(uint256[] memory breakPoints) external onlyAdmins {
        require(breakPoints.length == 3, "Improper Input");
        TokenFacetLib.getState().breakPoints = breakPoints;
    }

    /**
     * @dev admin only function to update prices
     * @param _price new public price to be set
     * @param _priceAL new allowlist price to be set
     */
    function setPrices(uint256 _price, uint256 _priceAL) external onlyAdmins {
        TokenFacetLib.getState().price[uint256(TokenFacetLib.PriceType.Allowlist)] = _priceAL;
        TokenFacetLib.getState().price[uint256(TokenFacetLib.PriceType.Public)] = _price;
    }

    /**
     * @dev admin only function to update name
     *      for the collection
     * @param name new name to be set
     */
    function setName(string memory name) external onlyAdmins {
        ERC721AStorage.layout()._name = name;
    }

    /**
     * @dev admin only function to update symbol
     *      for the collection
     * @param symbol new symbol to be set
     */
    function setSymbol(string memory symbol) external onlyAdmins {
        ERC721AStorage.layout()._symbol = symbol;
    }

    /**
     * @dev admin only function to update image array used 
     *      for generating metadata
     * @param image array of strings to construct metadata
     */
    function setImage(string[] memory image) external onlyAdmins {
        TokenFacetLib.getState().image = image;
    }

    function setBaseURI(string memory uri) external onlyAdmins {
        TokenFacetLib.getState().baseURI = uri;
    }

    /**
     * @dev admin only function to change duration of image change
     * @param time seconds in which image should change
     */
    function setUnitDuration(uint256 time) external onlyAdmins {
        TokenFacetLib.getState().unitDuration = time;
    }

    /**
     * @dev admin only function to change revealTimeStamp
     * @param time timestamp of when the metadata has to be revealed
     */
    function setRevealTimeStamp(uint256 time) external onlyAdmins {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        time == 0 ? s.revealTimeStamp = block.timestamp : s.revealTimeStamp = time;
    }

    /**
     * @dev admin only function to change preRevealURI
     * @param uri new uri string to be set
     */
    function setPreRevealURI(string memory uri) external onlyAdmins {
        TokenFacetLib.getState().preRevealURI = uri;
    }
    /**
     * @dev admin only function to change postRevealURI
     * @param uri new uri string to be set
     */
    function setPostRevealURI(string memory uri) external onlyAdmins {
        TokenFacetLib.getState().postRevealURI = uri;
    }

    /**
     * @dev admin only function that toggles burn status to control
     *      whether tokens can be burned or not
     */
    function toggleBurnStatus() external onlyAdmins {
        TokenFacetLib.getState().burnStatus = !TokenFacetLib.getState().burnStatus;
    }

    /**
     * @dev admins only function to set timestamp for starting sale
     * @param time timestamp to start sale or 0 to stop
     *                      sale now
     */
    function startSale(uint256 time) external onlyAdmins {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        time == 0 ? s.startTimeStamp = block.timestamp : s.startTimeStamp = time;
    }

    /**
     * @dev admins only function to set timestamp for ending sale
     * @param time timestamp to end sale or 0 to stop
     *                      sale now
     */
    function stopSale(uint256 time) external onlyAdmins {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        time == 0 ? s.endTimeStamp = block.timestamp : s.endTimeStamp = time;
    }

    /**
     * @dev admin only function to set Day for each particular
     *      city
     * @param day array of days for which city has to be set
     * @param city array of city names which have to be set
     *              for given days in first param
     */
    function setDayToCity(uint256[] memory day, string[] memory city) external onlyAdmins {
        require(day.length == city.length, "improper input");

        TokenFacetLib.state storage s = TokenFacetLib.getState();

        s.day = day;
        s.city = city;
    }

    /**
     * @dev admin-only function to mint batch mint NFTs to given
     *      list of addresses and list of amount to respective
     *      address
     * @param recipient array of addresses to be minted NFTs to
     * @param amount    array of amount of NFTs minted to addresses
     *                  first param
     */
    function reserve(address[] memory recipient, uint256[] memory amount) external onlyAdmins {
        require(
            recipient.length == amount.length,
            "TokenFacet: invalid inputs"
        );
        GlobalState.requireCallerIsAdmin();
        for(uint256 i; i < recipient.length;) {
            _safeMint(recipient[i], amount[i]);
            unchecked{
                i++;
            }
        }
    }

    // PUBLIC FUNCTIONS //

    /**
     * @dev mint function intended to be directly called by users
     * @param quantity number of NFTs that the user wants to purchase
     * @param _merkleProof  Send merkle proof for allowlist addresses
     *                      otherwise send empty array for public
     *                      purchase
     */
    function mint(uint256 quantity, bytes32[] calldata _merkleProof) external payable contractNotPause {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        require(isSaleOpen(), "TokenFacet: token sale is not available now");

        bool al = _merkleProof.length != 0;
        if(al) {
            AllowlistLib.requireValidProof(_merkleProof);
        }

        uint256 _price = al ? s.price[uint256(TokenFacetLib.PriceType.Allowlist)] : s.price[uint256(TokenFacetLib.PriceType.Public)];
        require(msg.value == _price * quantity, "TokenFacet: incorrect amount of ether sent");

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev function for user to burn their token
     * @param tokenId token which has to be burned
     */
    function burn(uint256 tokenId) external contractNotPause {
        require(TokenFacetLib.getState().burnStatus, "TokenFacet: token burning is not available now");

        _burn(tokenId, true);
    }

    /**
     * @dev allow users to forge their metadata
     * @param tokenId token whose metadata has to be forge
     */
    function forge(uint256 tokenId) external contractNotPause {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        require(s.forged[tokenId] == 0, "URI already forged for tokenId");
        require(ownerOf(tokenId) == msg.sender, "Only owners can forge URI");

        uint256 revealTimeStamp = s.revealTimeStamp;
        require(revealTimeStamp != 0, "TokenFacet: cannot forge uri before sale has started");
        uint256 DAY_NUMBER = ((block.timestamp - revealTimeStamp) / s.unitDuration) + 1;
        
        s.forged[tokenId] = DAY_NUMBER;
    }

    // METADATA & MISC FUNCTIONS //

    /**
     * @dev returns number of seconds remaining in metadata change
     */
    function remainingSeconds() external view returns (uint256) {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        uint256 unitduration = s.unitDuration;
        uint256 timeStamp = s.revealTimeStamp;
        if(block.timestamp >= timeStamp && timeStamp != 0) {
            return (timeStamp + ((((block.timestamp - timeStamp) / unitduration) + 1) * unitduration)) - block.timestamp;
        }
        return timeStamp - block.timestamp;
    }

    /**
     * @dev returns current day in metadata calculation
     */
    function currentDay() external view returns (uint256) {
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        uint256 DAY_NUMBER;
        uint256 timeStamp = s.revealTimeStamp;
        if(block.timestamp >= timeStamp && timeStamp != 0) {
            DAY_NUMBER = ((block.timestamp - timeStamp) / s.unitDuration) + 1;
        }
        return DAY_NUMBER;
    }

    /**
     * @dev calculates the currentDay for the token and returns metadata
     *      based on that
     * @param tokenId tokenId whose metadata is to be requested
     * @return string metadata of the given tokenId
     */
    function tokenURI(uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) view returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        TokenFacetLib.state storage s = TokenFacetLib.getState();
        uint256 timeStamp = s.revealTimeStamp;
        uint256 forged = uint256(s.forged[uint256(tokenId)]);
        
        if(block.timestamp >= timeStamp && timeStamp != 0) {
                uint256 DAY_NUMBER;
                if(forged != 0) DAY_NUMBER = forged;
                else DAY_NUMBER = ((block.timestamp - timeStamp) / s.unitDuration) + 1;
                uint256[] memory breakPoints = s.breakPoints;

                if(DAY_NUMBER >= breakPoints[0] && DAY_NUMBER < breakPoints[1]) {
                    return TokenFacetLib.generateMetadata(DAY_NUMBER, tokenId);
                } else if(DAY_NUMBER >= breakPoints[1] && DAY_NUMBER < breakPoints[2]) {
                    uint256 length = breakPoints[2] - breakPoints[1];
                    uint256[] memory array = new uint256[](length);

                    for(uint256 i; i < length;) {
                        array[i] = i + breakPoints[1];
                        unchecked {
                            i++;
                        }
                    }

                    for(uint256 i = length - 1; i > 0; i--) {
                        uint256 j = TokenFacetLib.random((tokenId), i + 1);
                        (array[i], array[j]) = (array[j], array[i]);
                    }

                    uint256 currentDay = array[DAY_NUMBER - breakPoints[1]];
                    return TokenFacetLib.generateMetadata(currentDay, tokenId);
                } else if (DAY_NUMBER >= breakPoints[2]) {
                    return TokenFacetLib.generateMetadata(breakPoints[2], tokenId);
                }
        } else {
            return TokenFacetLib.generateMetadata(0, tokenId);
        }
        return "";
    }

    /**
     * @dev checks whether a given tokenId exists or not
     * @param tokenId tokenId whose existance you want to check
     * @return bool returns true if given tokenId exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // INTERNAL FUNCTIONS //

    /**
     * @dev Modifier the hook to check for pause variable
     * @param from sender
     * @param to new owner
     * @param startTokenId starting tokenId for the transfer 
     * @param quantity number of tokens to be sent
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        GlobalState.requireContractIsNotPaused();
    }
}