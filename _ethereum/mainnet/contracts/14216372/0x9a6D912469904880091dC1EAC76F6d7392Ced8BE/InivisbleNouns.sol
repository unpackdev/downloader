// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Invisible Nouns
 * @notice Completely on-chain derivative of Nouns, https://invisiblenouns.wtf
 */

/*********************************
 *                               *
 *                               *
 *       █████████  █████████    *
 *       ██   ████  ██   ████    *
 *   ██████   ████████   ████    *
 *   ██  ██   ████  ██   ████    *
 *   ██  ██   ████  ██   ████    *
 *       █████████  █████████    *
 *                               *
 *                               *
 *********************************/

import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

struct Seed {
    uint48 background;
    uint48 body;
    uint48 accessory;
    uint48 head;
    uint48 glasses;
}

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

interface NounsToken {
    function seeds(uint256) external view returns (Seed memory);
    function descriptor() external view returns (address);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
}

interface NounsDescriptor {
    function generateSVGImage(Seed memory) external view returns (string memory);
}

contract InvisibleNouns is ERC721, IERC2981, Ownable {
    using Strings for uint256;
    event Payout(address indexed tokenOwner, uint value);

    string private _contractCID;
    NounsToken public immutable nounsToken;
    NounsDescriptor public immutable nounsDescriptor;
    ProxyRegistry public immutable proxyRegistry;
    uint256 public price;
    bool public priceLocked = false;
    uint256 public totalSupply;

    constructor(address _nounsToken, address _proxyRegistry, uint256 _price, string memory contractCID) ERC721("Invisible Nouns", "INVISNOUN") {
        nounsToken = NounsToken(_nounsToken);
        nounsDescriptor = NounsDescriptor(NounsToken(_nounsToken).descriptor());
        proxyRegistry = ProxyRegistry(_proxyRegistry);
        price = _price;
        _contractCID = contractCID;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        Seed memory seed = nounsToken.seeds(tokenId);
        seed.head = uint48(198); //stapler, the shortest code
        bytes memory image = Base64.decode((nounsDescriptor.generateSVGImage(seed)));
        require(image.length > 1110, "Wrong SVG");
        assembly {
            let end := sub(add(image, mload(image)), 1078) //1110 (stapler svg length) - 32
            for { let i := add(image, 32) } lt(i, end) { i := add(i, 1) } {
                if eq(mload(i), 0x3c726563742077696474683d2231333022206865696768743d2231302220783d) { //0-32 bytes of stapler head
                    if eq(mload(add(i, 32)), 0x223131302220793d223830222066696c6c3d222366333332326322202f3e3c72) { //32-64 bytes of stapler head
                        if eq(mload(add(i, 64)), 0x6563742077696474683d2231383022206865696768743d2231302220783d2238) { //64-96 bytes of stapler head
                            if eq(mload(add(i, 96)), 0x302220793d223930222066696c6c3d222366333332326322202f3e3c72656374) { //96-128 bytes of stapler head
                                for { let j := i } lt(j, end) { j := add(j, 32) } {
                                    mstore(j, mload(add(j, 1110)))
                                }
                                i := end
                            }
                        }
                    }
                }
            }
            mstore(image, sub(mload(image), 1110))
        }
        string memory nounId = tokenId.toString();
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"Invisible Noun ', nounId, '", "description":"Invisible Noun ', nounId, ' is a derivative of the Noun ', nounId, '", "image": "', 'data:image/svg+xml;base64,', Base64.encode(image), '"}')
                    )
                )
            )
        );
    }

    function contractURI() public view returns (string memory) {
        require(bytes(_contractCID).length > 0);
        return string(abi.encodePacked('ipfs://', _contractCID));
    }

    function setContractURI(string memory newContractCID) external onlyOwner {
        _contractCID = newContractCID;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        require(!priceLocked, "Price locked");
        price = newPrice;
    }

    function lockPrice() external onlyOwner {
        priceLocked = true;
    }

    function isApprovedForAll(address owner, address operator) override(ERC721) public view returns (bool) {
        if (proxyRegistry.proxies(owner) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(this);
        royaltyAmount = _salePrice / 20; //5%
    }

    function mint() external payable {
        uint256 nounsTotalSupply = nounsToken.totalSupply() - 1; //Do not mint while the last Noun is at auction
        uint256 tokenId = totalSupply;
        require(tokenId < nounsTotalSupply, "Please wait for the next Noun");
        require(msg.value >= price, "Not enough ETH");
        _mint(msg.sender, tokenId);
        totalSupply = tokenId + 1;
        try nounsToken.ownerOf(tokenId) returns (address tokenOwner) {
            uint half = msg.value / 2;
            (bool success, ) = tokenOwner.call{value: half, gas: 30_000}(""); //Send 50% to the Noun owner
            if (success) emit Payout(tokenOwner, half);
        } catch (bytes memory) {}
    }

    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }

    function airdrop(uint256 count) external onlyOwner {
        require(totalSupply == 0, "Only once");
        for (uint256 tokenId = 0; tokenId < count; tokenId++) {
            try nounsToken.ownerOf(tokenId) returns (address tokenOwner) {
                _mint(tokenOwner, tokenId);
            } catch (bytes memory) {
                _mint(owner(), tokenId);
            }
        }
        totalSupply = count;
    }
}
