// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./SafeERC20.sol";

contract AlienVersePreMint is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using Strings for uint256;
    string _symbol;
    string private constant version = "1";
    address public cfo = address(0xa5Ac27269a7Da1066CAb22C8D3A3a067E97D4ee0);
    address private _validator = address(0xe788592327C91000308Ba84345bAB8952B506662);

    uint256 public constant WL_MINT_PRICE = 0.063 ether;

    uint256 public totalMintedCount = 0;
    // mapping(string => address) public whiteMintCodeAddresses;

    uint256 public whiteMintStart;
    uint256 public whiteMintEnd;
    mapping(string => address) public _minted_code;

    bytes32 private constant WHITELIST_MINT_TYPEHASH =
    keccak256(
        "whiteListMint(address to,string code)"
    );

    error InvalidSign();

    constructor(
        string memory name,
        string memory symbol,
        address validator,
        uint256 whiteMintStart_,
        uint256 whiteMintEnd_
    ) payable EIP712(name, version) {
        _symbol = symbol;
        _validator = validator;
        whiteMintStart = whiteMintStart_;
        whiteMintEnd = whiteMintEnd_;
    }

    function verifySignature(
        address to,
        string memory code,
        bytes calldata signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WHITELIST_MINT_TYPEHASH,
                    to,
                    keccak256(bytes(code))
                )
            )
        );
        if (ECDSA.recover(digest, signature) != _validator) {
            revert InvalidSign();
        }
        return _validator;
    }


    function whiteListMint(string memory code, address to, bytes calldata signature) public payable {
        require(
            whiteMintStart == 0 || block.timestamp >= whiteMintStart,
            "sale has not started yet"
        );
        require(
            whiteMintEnd == 0 || block.timestamp <= whiteMintEnd,
            "sale has end"
        );

        require(_minted_code[code] == address(0), "mint code has been used");
        uint256 totalCost = WL_MINT_PRICE;
        require(msg.value == totalCost, "Need to check ETH value.");
        verifySignature(to, code, signature);

        _minted_code[code] = to;
        totalMintedCount += 1;
        payable(cfo).transfer(totalCost);
    }

    function minted_code(string memory code) public view returns (bool) {
        return _minted_code[code] != address(0);
    }

    function getMintedAddress(string memory code) public view returns (address) {
        return _minted_code[code];
    }

    function setValidator(address validator) public onlyOwner {
        _validator = validator;
    }

    function setWhiteMintStart(uint256 whiteMintStart_) public onlyOwner {
        whiteMintStart = whiteMintStart_;
    }

    function setWhiteMintEnd(uint256 whiteMintEnd_) public onlyOwner {
        whiteMintEnd = whiteMintEnd_;
    }

    function setCFO(address _cfo) public onlyOwner {
        cfo = _cfo;
    }

    /**
        @dev In case token get Stuck in the contract
    */
    function withdrawToken(address token, uint256 value) public onlyOwner {
        address to = msg.sender;
        IERC20(token).safeTransfer(to, value);
        // emit WithdrawToken(token, to, value);
    }

    /**
        @dev In case money get Stuck in the contract
    */
    function withdraw(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }
}
