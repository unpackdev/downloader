/*
    Copyright 2021 Project Galaxy.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

//import "SafeMath.sol";
//import "Address.sol";
import "ERC1155.sol";
import "Ownable.sol";


import "IStarNFT.sol";


/**
 * based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
 */
contract StarNFTV1Cap is ERC1155, IStarNFT, Ownable {
    using SafeMath for uint256;
    //    using Address for address;
    //    using ERC165Checker for address;

    /* ============ Events ============ */
    event EventMinterAdded(address indexed newMinter);
    event EventMinterRemoved(address indexed oldMinter);
    /* ============ Modifiers ============ */
    /**
     * Only minter.
     */
    modifier onlyMinter() {
        require(minters[msg.sender], "must be minter");
        _;
    }
    /* ============ Enums ================ */
    /* ============ Structs ============ */
    /* ============ State Variables ============ */

    // Used as the URI for all token types by ID substitution, e.g. https://galaxy.eco/{address}/{id}.json
    string public baseURI;

    // Mint and burn star.
    mapping(address => bool) public minters;

    // Total star count, including burnt nft.
    uint256 public starCount;

    // Total supply.
    uint256 public totalSupply;

    /* ============ Constructor ============ */
    constructor (uint256 totalSupply_) ERC1155("") {
        totalSupply = totalSupply_;
    }

    /* ============ External Functions ============ */

    function mint(address account, uint256 powah) external onlyMinter override returns (uint256) {
        require(totalSupply.sub(starCount) > 0, "Exceeded total supply");
        starCount++;
        uint256 sID = starCount;

        _mint(account, sID, 1, "");
        return sID;
    }

    function mintBatch(address account, uint256 amount, uint256[] calldata powahArr) external onlyMinter override returns (uint256[] memory) {
        require(totalSupply.sub(starCount) >= amount, "Exceeded total supply");
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint i = 0; i < ids.length; i++) {
            starCount++;
            ids[i] = starCount;
            amounts[i] = 1;
        }
        _mintBatch(account, ids, amounts, "");
        return ids;
    }

    function burn(address account, uint256 id) external onlyMinter override {
        require(isApprovedForAll(account, _msgSender()), "ERC1155: caller is not approved");

        _burn(account, id, 1);
    }

    function burnBatch(address account, uint256[] calldata ids) external onlyMinter override {
        require(isApprovedForAll(account, _msgSender()), "ERC1155: caller is not approved");

        uint256[] memory amounts = new uint256[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            amounts[i] = 1;
        }

        _burnBatch(account, ids, amounts);
    }

    function increaseSupply(uint256 quantity) external onlyOwner {
        totalSupply = totalSupply.add(quantity);
    }

    function decreaseSupply(uint256 quantity) external onlyOwner {
        totalSupply = totalSupply.sub(quantity);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new baseURI for all token types.
     */
    function setURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Add a new minter.
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "Minter must not be null address");
        require(!minters[minter], "Minter already added");
        minters[minter] = true;
        emit EventMinterAdded(minter);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Remove a old minter.
     */
    function removeMinter(address minter) external onlyOwner {
        require(minters[minter], "Minter does not exist");
        delete minters[minter];
        emit EventMinterRemoved(minter);
    }

    /* ============ External Getter Functions ============ */
    /**
     * See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 id) external view override returns (string memory) {
        require(id <= starCount, "NFT does not exist");
        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(baseURI).length == 0) {
            return "";
        } else {
            // bytes memory b = new bytes(32);
            // assembly { mstore(add(b, 32), id) }
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(baseURI, uint2str(id), ".json"));
        }
    }

    /**
     * Is the nft owner.
     * Requirements:
     * - `account` must not be zero address.
     */
    function isOwnerOf(address account, uint256 id) public view override returns (bool) {
        return balanceOf(account, id) == 1;
    }

    function getNumMinted() external view override returns (uint256) {
        return starCount;
    }

    /* ============ Internal Functions ============ */
    /* ============ Private Functions ============ */
    /* ============ Util Functions ============ */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }
}
