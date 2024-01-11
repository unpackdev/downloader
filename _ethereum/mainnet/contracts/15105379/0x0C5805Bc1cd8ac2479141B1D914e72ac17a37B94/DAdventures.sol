// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";

contract DininhoAdventures is ERC721AQueryable, ERC721ABurnable, EIP712, Ownable {
    uint public constant MAX_SUPPLY = 5600;
    uint public constant NORMAL_UNIT_PRICE = 0.03 ether;
    uint public constant MAX_PER_ACCOUNT = 2;
    uint public salesStartTimestamp = 1725443369;
    address private constant _SIGNER_PUBLIC_KEY = 0xc127A4c0c8C28F0a6c42010584EC6C2D9DC45Fd0;
    mapping(address => bool) private _usedWhitelistedAccounts;
    mapping(address => uint) private _totalMintsPerAccount;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Dininho Adventures", "DNA") EIP712("Dininho Adventures", "1.0.0") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(isSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");
        require(msg.value == amount * NORMAL_UNIT_PRICE, "invalid mint price");
        require(amount + totalSupply() <= MAX_SUPPLY, "amount exceeds max supply");
        require(amount + _totalMintsPerAccount[msg.sender] <= MAX_PER_ACCOUNT, "account cannot mint more than 2 tokens");

        _totalMintsPerAccount[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function whitelistMint(bytes calldata signature) external {
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(_recoverAddress(msg.sender, signature) == _SIGNER_PUBLIC_KEY, "account is not whitelisted");
        require(!hasUsedWhitelistAccount(msg.sender), "account already used");
        require(_totalMintsPerAccount[msg.sender] <= MAX_PER_ACCOUNT, "account cannot mint more than 2 tokens");

        _usedWhitelistedAccounts[msg.sender] = true;
        _totalMintsPerAccount[msg.sender]++;

        _safeMint(msg.sender, 1);
    }

    function hasUsedWhitelistAccount(address account) public view returns (bool) {
        return _usedWhitelistedAccounts[account];
    }

    function isSalesActive() public view returns (bool) {
        return salesStartTimestamp <= block.timestamp;
    }

    function setSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        salesStartTimestamp = newTimestamp;
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account) private view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Dininho Adventures(address account)"),
                    account
                )
            )
        );
    }

    function _recoverAddress(address account, bytes calldata signature) private view returns (address) {
        return ECDSA.recover(_hash(account), signature);
    }
}
