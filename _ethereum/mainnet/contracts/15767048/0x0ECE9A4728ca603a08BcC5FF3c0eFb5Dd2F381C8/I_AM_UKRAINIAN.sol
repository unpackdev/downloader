// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract I_AM_UKRAINIAN is ERC721, Ownable {
    string private baseURI =
        "ipfs://QmVht4TEniKhc2XPDhZw4SVv9K8WdyCzdRHGF761mjUFdg/";
    string private baseContractURI =
        "ipfs://QmeRMfUzVGjjsPTpBYRdnZfjSQ6u3N6vdDi2LSpVdELJsA";
    uint256 internal currentIndex;
    address immutable _minter;

    constructor() ERC721("I AM UKRAINIAN", "IAMU") {
        _minter = msg.sender;
        _mint(msg.sender, 10000, "", false);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function changeBaseContractURI(string calldata newURI) public onlyOwner {
        baseContractURI = newURI;
    }

    function totalSupply() public view virtual returns (uint256) {
        return currentIndex;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(tokenId < totalSupply(), "invalid token ID");
        if (owner == address(0)) {
            return _minter;
        } else {
            return owner;
        }
    }

    function safeMint(address to, uint256 quantity) public virtual onlyOwner {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) private {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "mint to the zero address");
        require(quantity != 0, "quantity must be greater than 0");

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;
            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);

                if (safe) {
                    _owners[updatedIndex] = to;
                    require(
                        _checkOnERC721Received(
                            address(0),
                            to,
                            updatedIndex,
                            _data
                        ),
                        "ERC721A: transfer to non ERC721Receiver implementer"
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
