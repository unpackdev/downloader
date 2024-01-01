// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TokenBank is Ownable {
    string public name;
    string public version;
    address public signer;
    bytes32 public DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant CHEQUE_TYPEHASH =
        keccak256(
            "Cheque(address token,address account,uint256 amount,uint256 nonce)"
        );

    mapping(uint256 => bool) public nonces;

    event Claim(
        address indexed token,
        address indexed account,
        uint256 amount,
        uint256 nonce
    );

    constructor(string memory _name, string memory _version, address _signer) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
                address(this)
            )
        );
        name = _name;
        version = _version;
        signer = _signer;
    }

    function _hashCheque(
        address _token,
        address _account,
        uint256 _amount,
        uint256 _nonce
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            CHEQUE_TYPEHASH,
                            _token,
                            _account,
                            _amount,
                            _nonce
                        )
                    )
                )
            );
    }

    function claim(
        address _token,
        address _account,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external {
        require(!nonces[_nonce], "Nonce has been used.");
        nonces[_nonce] = true;

        bytes32 chequeHash = _hashCheque(_token, _account, _amount, _nonce);
        address recoveredSigner = ECDSA.recover(chequeHash, _signature);
        require(recoveredSigner == signer, "Signature is error.");

        if (_token == address(0)) {
            payable(_account).transfer(_amount);
        } else {
            IERC20(_token).transfer(_account, _amount);
        }

        emit Claim(_token, _account, _amount, _nonce);
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                owner(),
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    receive() external payable {}
}
