// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}



contract SupdoodleducksStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;
    address public stakingDestinationAddress = 0x23988C2130b2D8A8334e85de4053C68A1e1F1639;
    mapping(address => EnumerableSet.UintSet) private deposits;
    mapping(uint256 => address) private tokenofaddr;
    mapping(uint256 => uint) private staketokentimestamp;
    struct WinnerResult {
        address winneraddress;
        uint256 winnertokenid;
    }
    WinnerResult[] public WinnerResults;

    /*
    * Open the lottery session
    * @_tokenIds eligible for the lottery Qualified tokenids
    * @ethprice the eth price of the FTX exchange at the moment of the lottery, with the price taken as an integer part
    */
    function querywinnerbytokens(uint256[] calldata _tokenIds, uint256 ethprice) public view returns (uint256, address) {
        uint256 wintokenid;
        address winneraddress;
        uint256 seedinput;
        for (uint256 i; i < _tokenIds.length; i++) {
            seedinput = seedinput + _tokenIds[i] + ethprice;
        }
        seedinput = seedinput + block.timestamp;
        uint256 rand = random(string(abi.encodePacked(seedinput.toString())));
        uint256 index = rand % _tokenIds.length;
        wintokenid = _tokenIds[index];
        winneraddress = queryownerbytoken(_tokenIds[index]);
        return (wintokenid, winneraddress);
    }


    /*
    * Query the tokenid that matches the pledge time
    * @time the time of the pledge to be inquired about
    * @staketokenIds the tokenids to query
    */
    function querystaketokenbytimestamp(uint time, uint256[] calldata staketokenIds) public view returns (uint256[] memory) {
        uint[] memory stakestamp;
        uint256[] memory staketokenqualifiedIds = new uint256[] (staketokenIds.length);
        stakestamp = querystaketimebytokens(staketokenIds);
        for (uint256 i; i < stakestamp.length; i++) {
            if (stakestamp[i] >= time) {
                staketokenqualifiedIds[i] = staketokenIds[i];
            } else {
                staketokenqualifiedIds[i] = 0;
            }
        }
        return staketokenqualifiedIds;
    }


    /**
    * Query the tokenid of all pledged nft's at this address
    * @param _account the address of the staker
    */
    function querystaketokenbyaddress(address _account) public view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = deposits[_account];
        uint256[] memory tokenIds = new uint256[] (depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }

    /**
    * Query the pledge time of nft
    * @param _tokenIds to query the tokenid of all nft
    */
    function querystaketimebytokens(uint256[] calldata _tokenIds) public view returns (uint[] memory) {
        uint[] memory tokenstaketime = new uint[] (_tokenIds.length);
        for (uint256 i; i < _tokenIds.length; i++) {
            tokenstaketime[i] = block.timestamp - staketokentimestamp[_tokenIds[i]];
        }
        return tokenstaketime;
    }

    /**
    * Query the current nft holder's address
    * @param _tokenId to query the tokenid of nft
    */
    function queryownerbytoken(uint256 _tokenId) public view returns (address) {
        return tokenofaddr[_tokenId];
    }

    /**
    * Internal randomized algorithm
    */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /**
    * Pledge the nft selected by the user to the lottery pool
    * @param _tokenIds to pledge the tokenid of nft
    */
    function deposit(uint256[] calldata _tokenIds) external {
        require(msg.sender != stakingDestinationAddress, "Invalid address");
        require(tx.origin == msg.sender, "Only EOA");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(IERC721(stakingDestinationAddress).ownerOf(_tokenIds[i]) == _msgSender(), "You don't own this token");
            deposits[msg.sender].add(_tokenIds[i]);
            staketokentimestamp[_tokenIds[i]] = block.timestamp;
            tokenofaddr[_tokenIds[i]] = msg.sender;
            IERC721(stakingDestinationAddress).safeTransferFrom(msg.sender, address(this), _tokenIds[i], "");
        }
    }

    /**
    *  Extract the nft selected by the user for pledging in the prize pool to the user's address
    * @param _tokenIds to extract the tokenid of nft
    */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant() {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(deposits[msg.sender].contains(_tokenIds[i]), "Staking: token not deposited");
            deposits[msg.sender].remove(_tokenIds[i]);
            staketokentimestamp[_tokenIds[i]] = 0;
            tokenofaddr[_tokenIds[i]] = address(0);
            IERC721(stakingDestinationAddress).safeTransferFrom(address(this), msg.sender, _tokenIds[i], "");
        }
    }

    /*
    * Administrator prize opening
    * @time pledge time conditions
    * @staketokenIds all pledged token
    * @ethprice ethprice the eth price of the FTX exchange at the moment of the lottery, with the price taken as an integer part
    */
    function openLottery(uint time, uint256[] calldata staketokenIds, uint256 ethprice) public onlyOwner {
        uint256[] memory lotterytokenids;
        uint256 seedinput;
        uint256 winnerindex;
        address winneraddr;
        lotterytokenids = querystaketokenbytimestamp(time, staketokenIds);
        seedinput = (block.timestamp + ethprice) * lotterytokenids.length ;
        winnerindex = random(string(abi.encodePacked(seedinput.toString()))) % lotterytokenids.length;
        winneraddr = queryownerbytoken(lotterytokenids[winnerindex]);
        WinnerResults.push(WinnerResult({
        winneraddress : winneraddr,
        winnertokenid : lotterytokenids[winnerindex]
        }));
    }


    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}