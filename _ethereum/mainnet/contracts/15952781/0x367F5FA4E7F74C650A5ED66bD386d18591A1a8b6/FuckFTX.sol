//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LilOwnable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";

error DoesNotExist();
error NoTokensLeft();
error MintNotStarted();
error TooManyMints();
error EmptyBalance();

contract FuckFTX is LilOwnable, ERC721 {
    using Strings for uint256;

    address public hater;
    uint256 public constant TOTAL_SUPPLY = 101;
    bool public mintStarted = false;
    uint256 public totalSupply;
    string public baseURI;

    constructor() payable ERC721("FuckFTX", "FFTX") {
        hater = msg.sender;
    }
    
    modifier biggestHater() {
        require(msg.sender == hater, "Ownable: caller is not the biggest hater");
        _;
    }

    function mint(uint16 amount) external payable {
        if (amount > 1) revert TooManyMints();
        if (totalSupply + amount > TOTAL_SUPPLY) revert NoTokensLeft();
        if (!mintStarted) revert MintNotStarted();

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply + 1);
                totalSupply++;
            }
        }
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setBaseURI(string memory _newBaseURI) public biggestHater {
        baseURI = _newBaseURI;
    }

    function startMint() public biggestHater {
        mintStarted = true;
    }
    
    function pauseMint() public biggestHater {
        mintStarted = false;
    }

    function withdraw() external biggestHater {
        if (address(this).balance == 0) revert EmptyBalance();
        payable(hater).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(LilOwnable, ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}