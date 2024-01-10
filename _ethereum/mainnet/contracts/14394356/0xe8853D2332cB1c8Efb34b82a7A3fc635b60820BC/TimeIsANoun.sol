// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Time Is A Noun
 * @notice Completely on-chain derivative of Nouns, https://timenouns.wtf
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
    function ownerOf(uint256) external view returns (address);
}

interface NounsDescriptor {
    function generateSVGImage(Seed memory) external view returns (string memory);
}

contract TimeIsANoun is ERC721, IERC2981, Ownable {
    using Strings for uint256;
    event Payout(address indexed tokenOwner, uint value);

    string private _contractCID;
    NounsToken public immutable nounsToken;
    NounsDescriptor public immutable nounsDescriptor;
    address public immutable nounsDAO;
    ProxyRegistry public immutable proxyRegistry;
    uint256 public constant price = 41560000 gwei;
    bool public priceLocked = false;
    uint256 public totalSupply;

    constructor(address _nounsToken, address _nounsDescriptor, address _nounsDAO, address _proxyRegistry, string memory contractCID) ERC721("Time Is A Noun", "TIMENOUN") {
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
        require(image.length > 1110, "Wrong SVG");
        assembly {
            let end := sub(add(image, mload(image)), 134) //166  - 32
            for { let i := add(image, 32) } lt(i, end) { i := add(i, 32) } {
                mstore(i, mload(add(i, 166)))
            }
            mstore(image, sub(mload(image), 166))
        }
        string memory nounId = tokenId.toString();
        bytes memory parts;
        string[16] memory x = ['0', '10', '60', '80', '130', '170', '210', '190', '160', '220', '180', '200', '240', '250', '250', '250'];
        string[16] memory y = ['0', '10', '30', '40', '30', '30', '30', '80', '60', '60', '60', '60', '30', '30', '60', '90'];
        string[16] memory width = ['340', '320', '50', '10', '10', '10', '10', '10', '10', '10', '10', '10', '10', '30', '30', '30'];
        string[16] memory height = ['420', '400', '10', '60', '70', '30', '30', '20', '40', '40', '20', '20', '70', '10', '10', '10'];
        string[10] memory colors = ['#000000', '#1f1d29', '#3a085b', '#410d66', '#2b2834', '#1e3445', '#4d271b', '#343235', '#552e05', '#0b5027'];
        
        for (uint256 i = 0; i < 16; i++) {
            string memory fill = i == 0 ? "#E02826" : i == 1 ? colors[tokenId % 10] : "white";
            parts = abi.encodePacked(parts, '<rect x="', x[i] , '" y="', y[i] , '" width="', width[i] , '" height="', height[i], '" fill="', fill, '"/>');
        }
        string memory svgTag = 'fill="none" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
        image = abi.encodePacked(
            '<svg width="340" height="420" viewBox="0 0 340 420" ',
            svgTag,
            parts, '<svg x="10" y="90" width="320" height="320" viewBox="0 0 320 320" ', svgTag, image, '</svg>');
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"Time Is A Noun ', nounId, '", "description":"Time Is A Noun ', nounId, ' is a derivative of the Noun ', nounId, '", "image": "', 'data:image/svg+xml;base64,', Base64.encode(image), '"}')
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
        royaltyAmount = _salePrice / 20; //5%
    }

    function mint() external payable {
        uint256 nounsTotalSupply = nounsToken.totalSupply() - 1; //Do not mint while the last Noun is at auction
        uint256 tokenId = totalSupply;
        require(tokenId < nounsTotalSupply, "Please wait for the next Noun");
        require(msg.value >= price, "Not enough ETH");
        _mint(msg.sender, tokenId);
        totalSupply = tokenId + 1;
        if (tokenId % 10 == 0) {
            (bool success, ) = nounsDAO.call{value: msg.value, gas: 30_000}(""); // Send 100% to the Nouns DAO
            if (success) emit Payout(nounsDAO, msg.value);
        }
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
