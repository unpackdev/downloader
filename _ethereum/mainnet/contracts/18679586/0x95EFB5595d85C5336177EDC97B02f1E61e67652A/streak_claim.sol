// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./MerkleProof.sol";

pragma solidity ^0.8.21;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.21;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.21;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.21;

contract Claim is Ownable {
    IERC20 public token;

    bytes32 public merkleRoot;
    mapping(address => bool) public userClaimed;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setToken(address _target) external onlyOwner {
        token = IERC20(_target);
    }

    function checkProof(
        bytes32[] memory _proof,
        uint256 _tokens,
        bytes32 root
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokens));
        return MerkleProof.verify(_proof, root, leaf);
    }

    function claimTokens(
        uint256 _tokens,
        bytes32[] memory _proof
    ) external {
        require(token.balanceOf(address(this)) >= _tokens, "Contract tokens depleted");
        require(!userClaimed[msg.sender], "User has already claimed");
        require(checkProof(_proof, _tokens, merkleRoot), "Invalid proof");
        userClaimed[msg.sender] = true;
        token.transfer(msg.sender, _tokens);
    }

    function manualRemoveTokens() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function manualRemoveEther() external onlyOwner {
        bool success;

        uint256 totalETH = address(this).balance;
        (success,) = address(owner()).call{value: totalETH}("");
    }

    function manualRemoveSpecificTokens(address _target) external onlyOwner {
        IERC20 tokenToRemove = IERC20(_target);
        tokenToRemove.transfer(msg.sender, tokenToRemove.balanceOf(address(this)));
    }
}
