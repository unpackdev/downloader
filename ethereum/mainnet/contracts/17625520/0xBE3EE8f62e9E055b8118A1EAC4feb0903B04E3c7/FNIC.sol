// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ODFNIC is ERC721A, ERC2981, Ownable {
    uint256 maxSupply = 333;
    string public tokenURI =
        "ipfs://bafkreie3speds3vjs3tntdwbu5izxtdlshqsavof3mxuhj5kmvcfh6lqca";

    error NoTokensLeft();

    constructor() ERC721A("OD F.N.I.C", "OD F.N.I.C") {
        setRoyaltyInfo(owner(), 333); // 3.33%
    }

    function airdropMint(address[] memory to) external onlyOwner {
        if (to.length + totalSupply() > maxSupply) revert NoTokensLeft();
        for (uint256 i; i < to.length; ++i) {
            _mint(to[i], 1);
        }
    }

    function mint(address _account, uint256 _amount) public onlyOwner {
        require(_amount + totalSupply() <= maxSupply);

        _mint(_account, _amount);
    }

    function setURI(string memory newuri) public onlyOwner {
        tokenURI = newuri;
    }

    function uri(uint256 _tokenId) public view returns (string memory) {
        return tokenURI;
    }

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function setRoyaltyInfo(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setRoyalties(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        setRoyaltyInfo(receiver, feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
