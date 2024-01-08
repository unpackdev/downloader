// SPDX-License-Identifier: UNLICENSED
/// @title Numbers
/// @notice Numbers on Tap (NFT Faucet)
/// @author CyberPnk <cyberpnk@numbersontap.cyberpnk.win>

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IStringUtilsV1.sol";
import "./INumbersOnTapRender.sol";

contract NumbersOnTap is ERC721 {
    uint public totalSupply = 0;
    uint public maxId;
    uint public maxMint = 10;
    IStringUtilsV1 stringUtils;
    INumbersOnTapRender render;
    address recipientAddress;

    constructor(uint maxPowerOfTen, address stringUtilsContract, address renderContract, address _recipientAddress) ERC721("NumbersOnTap", "NumbersOnTap") {
        maxId = 10**maxPowerOfTen;
        stringUtils = IStringUtilsV1(stringUtilsContract);
        render = INumbersOnTapRender(renderContract);
        recipientAddress = _recipientAddress;
    }

    // This is not a good way to shuffle things in solidity, because it's easily predicted
    // I just want to make things less boring, not provide strong randomness
    function getShuffled(uint index) view private returns(uint) {
      return ((27783 * index + 578) % maxId);
    }

    function claim(uint howMany) public {
        require(howMany > 0 && howMany <= maxMint && totalSupply + howMany < maxId, "Invalid howMany");
        for (uint i = 0; i < howMany; i += 1) {
            uint newItemId = totalSupply;
            totalSupply += 1;
            _safeMint(msg.sender, getShuffled(newItemId));
        }
    }

    function tokenURI(uint256 itemId) public view override returns (string memory) {
        return render.getTokenURI(itemId);
    }

    function contractURI() public view returns(string memory) {
        bytes memory json = abi.encodePacked(
        '{'
            '"name": "Numbers on Tap",'
            '"description": "Numbers on Tap is a faucet of free NFTs.",'
            '"image": "data:image/svg+xml;utf8,', render.getImage(1) ,'",'
            '"external_link": "https://numbersontap.click",'
            '"seller_fee_basis_points": 500,'
            '"fee_recipient": "', stringUtils.addressToString(recipientAddress), '"'
        '}');

        return stringUtils.base64EncodeJson(json);
    }

}
