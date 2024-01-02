/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ECDSA.sol";
import "./EIP712.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./LibSignature.sol";

contract LuxyMultichainTierToken is ERC20, Ownable, EIP712 {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    mapping(address => bool) operators;
    mapping(bytes => bool) public usedNonces; // To ensure one-time use of a signature
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    // EIP-712 variables
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant MINT_TYPEHASH =
        keccak256(
            "Mint(address to,uint256 value,uint256 nonce,uint256 deadline)"
        );

    constructor(
        address operator
    ) ERC20("DiscountLuxy", "DL") EIP712("DiscountLuxy", "1") {
        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    modifier onlyOperator() {
        require(
            operators[_msgSender()],
            "OperatorRole: caller is not the operator"
        );
        _;
    }

    function isOperator(address operator) external view returns (bool) {
        return operators[operator];
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function mintWithSignature(
        address to,
        uint256 value,
        bytes calldata signature,
        uint256 nonce,
        uint256 deadline
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        require(!usedNonces[signature], "Signature used before");
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINT_TYPEHASH, to, value, nonce, deadline))
        );

        // Recover the signer's address and compare to `operator`
        address signer = digest.recover(signature);
        require(operators[signer] == true, "Invalid signature");

        // Mark this signature as used
        usedNonces[signature] = true;

        // Mint the tokens
        _mint(to, value);
    }

    function burn(uint256 value) public {
        _burn(_msgSender(), value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            from == address(0) || to == address(0),
            "LuxyTierToken: Only mint and burn allowed"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
