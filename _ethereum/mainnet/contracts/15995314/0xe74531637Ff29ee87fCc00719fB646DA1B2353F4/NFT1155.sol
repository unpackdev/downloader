// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC1155Base.sol";

contract NFT1155 is Ownable, AccessControl, ERC1155Base {
    string public name;
    string public symbol;

    bytes4 private _MINT_WITH_ADDRESS = bytes4(keccak256("MINT_WITH_ADDRESS"));

    address public transferProxy;

    constructor(
        string memory _name,
        string memory _symbol,
        address signer,
        string memory contractURI,
        string memory tokenURIPrefix
    ) ERC1155Base(contractURI, tokenURIPrefix) {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        // _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Base)
        returns (bool)
    {
        return
            _MINT_WITH_ADDRESS == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Can be removed?
    function addSigner(address account) public onlyOwner {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeSigner(address account) public onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function mint(
        uint256 id,
        uint8 v,
        bytes32 r,
        bytes32 s,
        Fee[] memory fees,
        uint256 supply,
        string memory uri
    ) public {
        require(
            hasRole(
                DEFAULT_ADMIN_ROLE,
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(abi.encodePacked(this, id))
                        )
                    ),
                    v,
                    r,
                    s
                )
            ),
            "signer should sign tokenId"
        );
        // require(isSigner(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, id)))), v, r, s)), "signer should sign tokenId");
        _mint(_msgSender(), id, fees, supply, uri);

        // Approve self to support airdrop for token from airdrop()
        setApprovalForAll(address(this), true);
    }

    function setTransferProxy(address _transferProxy) public onlyOwner {
        require(transferProxy != _transferProxy, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        transferProxy = _transferProxy;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            // bypass checking for mint case
            if (creators[id] == from && creators[id] != address(0)) {
                if (to == address(0)) { // burn case
                    break;
                }
                if (transferProxy == address(0)) { // no transfer proxy set then let minter airdrop and do other transfer directly
                    break;
                }
                if (_msgSender() == address(this)) { // trigger by this contract, should be by airdrop
                    break;
                }
                // May need to check interface / abi / whatever
                require(
                    transferProxy == _msgSender(),
                    "MINTER_NOT_ALLOWED_TO_TRANSFER_OUT_OF_MARKETPLACE"
                );
                break;
            }
        }
    }

    function airdrop(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(creators[id] == from, "NFT1155: airdrop must be from minter");

        NFT1155(this).safeTransferFrom(from, to, id, amount, data);
    }
}
