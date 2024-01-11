//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract HapToken is ERC20, EIP712, Ownable, ReentrancyGuard {
    string private constant SIGNING_DOMAIN = "Haplo";
    string private constant SIGNATURE_VERSION = "1";

    struct HaploVoucher {
        string transactionId;
        address wallet;
        uint256 amount;
        uint256 creationDate;
        bytes signature;
    }

    struct Manager {
        address wallet;
        uint256 value;
    }

    address private voucherSigner;
    mapping(bytes => bool) signatureUsed;

    event SuccessMint(address _minter, uint256 amount, string transactionId);

    constructor(address minter, Manager[] memory managers)
        ERC20("HAPS", "HAPS")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        voucherSigner = minter;

        for (uint256 i = 0; i < managers.length; i++) {
            _mint(managers[i].wallet, managers[i].value);
        }
    }

    function updateVoucherSignerAddress(address signer) external onlyOwner {
        voucherSigner = signer;
    }

    function mintByAdmin(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function mint(HaploVoucher calldata userData) external nonReentrant {
        require(block.timestamp - 120 < userData.creationDate, "Old request");
        require(!signatureUsed[userData.signature], "Already claimed");

        address signer = _verify(userData);
        require(signer == voucherSigner, "Invalid signer");

        _mint(_msgSender(), userData.amount);

        signatureUsed[userData.signature] = true;

        emit SuccessMint(_msgSender(), userData.amount, userData.transactionId);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _hash(HaploVoucher calldata userData)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "HaploVoucher(string transactionId,address wallet,uint256 amount,uint256 creationDate)"
                        ),
                        keccak256(bytes(userData.transactionId)),
                        userData.wallet,
                        userData.amount,
                        userData.creationDate
                    )
                )
            );
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function _verify(HaploVoucher calldata userData)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(userData);
        return ECDSA.recover(digest, userData.signature);
    }
}
