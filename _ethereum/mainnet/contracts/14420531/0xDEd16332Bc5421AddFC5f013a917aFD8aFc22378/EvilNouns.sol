// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Evil Nouns
 * @notice Completely on-chain derivative of Nouns, https://evilnouns.wtf
 */

import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
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
    function totalSupply() external view returns (uint256);
}

interface NounsDescriptor {
    function generateSVGImage(Seed memory) external view returns (string memory);
}

contract EvilNouns is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    string private _contractCID;
    NounsToken public immutable nounsToken;
    NounsDescriptor public immutable nounsDescriptor;
    address public immutable nounsDAO;
    ProxyRegistry public immutable proxyRegistry;
    uint256 public totalSupply;

    constructor(address _nounsToken, address _nounsDescriptor, address _nounsDAO, address _proxyRegistry, string memory contractCID) ERC721("Evil Nouns", "EVILNOUN") {
        nounsToken = NounsToken(_nounsToken);
        nounsDescriptor = NounsDescriptor(_nounsDescriptor);
        nounsDAO = _nounsDAO;
        proxyRegistry = ProxyRegistry(_proxyRegistry);
        _contractCID = contractCID;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        Seed memory seed = nounsToken.seeds(tokenId);
        bytes memory image = Base64.decode((nounsDescriptor.generateSVGImage(seed)));
        image = abi.encodePacked(
            '<svg width="320" height="320" viewBox="0 0 320 320" fill="none" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            '<defs><filter id="evil"><feColorMatrix color-interpolation-filters="sRGB" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/></filter></defs>',
            '<g filter="url(#evil)">', image, '</g>',
            '</svg>'
        );
        string memory nounId = tokenId.toString();
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"Evil Noun ', nounId, '", "description":"Evil Noun ', nounId, ' Be Like", "image": "', 'data:image/svg+xml;base64,', Base64.encode(image), '"}')
                    )
                )
            )
        );
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractCID));
    }

    function setContractURI(string memory newContractCID) external onlyOwner {
        _contractCID = newContractCID;
    }

    function isApprovedForAll(address owner, address operator) override(ERC721) public view returns (bool) {
        if (proxyRegistry.proxies(owner) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(this);
        royaltyAmount = _salePrice * 7 / 200; //3.5%
    }

    function mint(uint256 amount) external payable {
        uint256 supply = totalSupply;
        require(supply + amount <= nounsToken.totalSupply(), "Please wait for the next Noun");
        require(msg.value >= amount * 0.035 ether, "Mint price is 0.035"); //evil numbers 0 3 5
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            if (tokenId % 10 == 0) {
                (bool success, ) = nounsDAO.call{value: 0.035 ether}(""); // Send 100% to the Nouns DAO
                if (!success) {} //it is OK
            }
            _mint(msg.sender, tokenId);
        }
        totalSupply = supply + amount;
    }

    function withdraw(address token, uint256 amount) external onlyOwner returns (bool) {
        bool success;
        if (token == address(0)) {
            (success, ) = msg.sender.call{value: amount}("");
        } else {
            success = IERC20(token).transfer(msg.sender, amount);
        }
        return success;
    }
}
