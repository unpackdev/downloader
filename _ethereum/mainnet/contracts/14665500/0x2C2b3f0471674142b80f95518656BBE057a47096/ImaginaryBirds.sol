//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract ImaginaryBirds is ERC721A, Ownable, Pausable {
    using Strings for uint256;

    uint256 public maxTokens = 4269;
    // Increased by 1 to avoid one arithmetic calculation when minting (gas savings)
    uint256 public maxTokensPerTx = 11;
    uint256 public price = 0.015 ether;

    string private baseURI;

    constructor(string memory _ipfsCID) ERC721A("Imaginary Birds", "IB") {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(
                abi.encodePacked(_baseURI(), (tokenId + 1).toString(), ".json")
            );
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed!");
    }

    function toggleSale() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    receive() external payable {}

    function mint(uint256 _amount) external payable whenNotPaused {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        require(msg.value >= price * _amount, "Not enough ETH");
        require(
            _amount > 0 && _amount < maxTokensPerTx,
            "Too many tokens per tx!"
        );
        _safeMint(msg.sender, _amount);
    }
}
