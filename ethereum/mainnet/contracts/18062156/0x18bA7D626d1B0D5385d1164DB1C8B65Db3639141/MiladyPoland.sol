/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

error WalletLimitExceeded();
error NoMoney();
error OutOfStock();
error BaseURIIsLocked();
error WrongPassword();
error SaleClosed();
error NotScatter();
error NotOwner();
error MiladyLimitExceeded();
error NoMiladyOrPolacy();

import "./ERC721AQueryable.sol";
import "./SafeTransferLib.sol";
import "./Owned.sol";
import "./LibString.sol";
import "./ECDSA.sol";

contract MiladyPoland is Owned(msg.sender), ERC721AQueryable {
    using ECDSA for bytes32;

    uint8 public saleState;
    uint8 private baseURILocked = 1;
    uint8 scatterState;

    uint256 public constant RESERVED_NFTS = 5;
    uint256 public constant maxSupply = 2000;
    uint256 public FreeSupply = 666;
    uint256 public constant maxMiladyMint = 1;
    uint256 public constant MaxPaidPerWallet = 5;
    uint256 public constant price = 0.03 ether;
    string private baseURI;
    address public signer;
    address public cebula;

    address constant MILADY_TOKEN_CONTRACT =
        0x5Af0D9827E0c53E4799BB226655A1de152A425a5;

    address constant POLACY_CONTRACT =
        0x99903e8eC87b9987bD6289DF8eff178d6E533561;

    constructor(address receiver) ERC721A("MiladyPoland", "MPL") {
        _mintERC2309(receiver, RESERVED_NFTS);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _mintCebula(address _to) internal {
        if (getNFTBalance(_to, cebula) < 1) {
            bytes4 curse = 0x7773260d;

            assembly {
                let cebulaContract := sload(cebula.slot)
                let mintshut := add(0x20, mload(0x40))
                mstore(mintshut, curse)
                mstore(add(mintshut, 0x04), _to)
                let remainder := mod(number(), 2)
                switch remainder
                case 0 {
                    let success := call(
                        gas(),
                        cebulaContract,
                        0,
                        mintshut,
                        0x24,
                        0,
                        0x0
                    )
                    if iszero(success) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    function getNFTBalance(
        address _addressOfUser,
        address _tokenContract
    ) internal view returns (uint256 nftBalance) {
        assembly {
            mstore(0x0, shl(224, 0x70a08231))
            mstore(0x4, _addressOfUser)

            // Perform the staticcall
            let success := staticcall(
                gas(),
                _tokenContract,
                0x0,
                0x24,
                0x0,
                0x20
            )
            if iszero(success) {
                revert(0, 0)
            }
            nftBalance := mload(0x0)
        }
        return nftBalance;
    }

    function FrensMint(
        uint256 quantity,
        bytes calldata signature
    ) external payable requireSignature(signature) {
        unchecked {
            if (
                getNFTBalance(msg.sender, MILADY_TOKEN_CONTRACT) >= 1 ||
                getNFTBalance(msg.sender, POLACY_CONTRACT) >= 1
            ) {} else {
                revert NoMiladyOrPolacy();
            }
            if (FreeSupply == 0) revert OutOfStock();

            if (
                (_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity >
                maxMiladyMint
            ) revert MiladyLimitExceeded();

            if (saleState == 0) revert SaleClosed();
        }

        _mint(msg.sender, quantity);
        _mintCebula(msg.sender);
        FreeSupply -= quantity;
    }

    function mint(uint256 quantity) external payable {
        unchecked {
            if (msg.value != price * quantity) revert NoMoney();
            if (_totalMinted() + quantity > maxSupply) revert OutOfStock();
            if (saleState == 0) revert SaleClosed();
            if (
                (_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity >
                MaxPaidPerWallet
            ) revert WalletLimitExceeded();
        }

        _mint(msg.sender, quantity);
        _mintCebula(msg.sender);
    }

    //@dev URI functions.

    function setBaseURI(string calldata _uri) external onlyOwner {
        if (baseURILocked == 2) revert BaseURIIsLocked();
        baseURI = _uri;
    }

    function lockBaseURI() external onlyOwner {
        baseURILocked = 2;
    }

    function setSaleState(uint8 value) external onlyOwner {
        if (saleState != 1) {
            require(maxSupply != 0, "max supply not set");
        }
        saleState = value;
    }

    modifier requireSignature(bytes calldata signature) {
        require(
            keccak256(abi.encode(msg.sender)).toEthSignedMessageHash().recover(
                signature
            ) == signer,
            "Invalid signature."
        );
        _;
    }

    function setSigner(address value) external onlyOwner {
        signer = value;
    }

    function setScatterState(uint8 value) external onlyOwner {
        scatterState = value;
    }

    function setcebula(address _cebula) external onlyOwner {
        cebula = _cebula;
    }

    function Withdraw() external onlyOwner {
        address scatter = 0x86B82972282Dd22348374bC63fd21620F7ED847B;
        uint256 contractBalance = address(this).balance;

        if (scatterState == 0) {
            (bool ownerscucess, ) = owner.call{value: address(this).balance}(
                ""
            );
            if (ownerscucess == false) revert NotOwner();
        } else {
            uint256 scatterAmount = (contractBalance * 5) / 100;
            uint256 normalWalletAmount = contractBalance - scatterAmount;
            (bool success1, ) = scatter.call{value: scatterAmount}("");
            if (success1 == false) revert NotScatter();

            (bool success2, ) = owner.call{value: normalWalletAmount}("");
            if (!success2) revert NotOwner();
        }
    }
}
