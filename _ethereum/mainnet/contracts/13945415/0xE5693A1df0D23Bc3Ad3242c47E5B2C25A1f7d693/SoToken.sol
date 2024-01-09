// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract SoToken is ERC20Burnable, Pausable, EIP712, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 private constant MAX_SUPPLY = 100 * (10**9) * (10**18);
    bytes32 public constant AIRDROP_CALL_HASH_TYPE =
        keccak256('Airdrop(address receiver,uint256 amount,address inviter,uint256 rewards)');

    event Airdrop(
        uint8 indexed airdropType,
        address indexed receiver,
        uint256 amount,
        address indexed inviter,
        uint256 rewards
    );

    mapping(address => bool) public transferWhitelist;
    mapping(uint8 => mapping(address => bool)) public airdropClaimed;
    mapping(uint8 => address) public airdropProvider;
    mapping(uint8 => address) public airdropSigner;

    constructor() ERC20('SomniLife', 'SO') EIP712('SomniLife', '1') {
        // 20B
        mint(0x1D18B432cccB5d317B5e2010E8456b6CF6D0BFD2, 20 * (10**9) * (10**18));
        // 10B
        mint(0xAeC1aFA5c4f806F8b39173E72d5b174660aF8830, 10 * (10**9) * (10**18));
        // 15B
        mint(0x063ae224230E67a51D2691Ae785179f258E5143A, 15 * (10**9) * (10**18));
        // 10B
        mint(0x57D5aD3E08E82825C0C773EC0F2a848d863906F9, 10 * (10**9) * (10**18));
        // 30B
        mint(0x6e9414CA38F058db7575457B711ECB2efe2674A7, 30 * (10**9) * (10**18));
        // 10B
        mint(0x1fcbC35a769face382E6a1978A5943BC89E9F178, 10 * (10**9) * (10**18));
        // 5B
        mint(0x401b9087C5dB93748d9c23881Aac8C0C54cfE553, 5 * (10**9) * (10**18));

        // airdrop 200M
        _approve(0x1fcbC35a769face382E6a1978A5943BC89E9F178, address(this), 200 * (10**6) * (10**18)); // save gas
        setAirdrop(0, 0x1fcbC35a769face382E6a1978A5943BC89E9F178, 0x22792eEBa92B2caf432789634beaDdC03cF9D6d4);

        setTransferWhitelist(address(0), true);
        setTransferWhitelist(0x1D18B432cccB5d317B5e2010E8456b6CF6D0BFD2, true);
        setTransferWhitelist(0xAeC1aFA5c4f806F8b39173E72d5b174660aF8830, true);
        setTransferWhitelist(0x063ae224230E67a51D2691Ae785179f258E5143A, true);
        setTransferWhitelist(0x57D5aD3E08E82825C0C773EC0F2a848d863906F9, true);
        setTransferWhitelist(0x6e9414CA38F058db7575457B711ECB2efe2674A7, true);
        setTransferWhitelist(0x401b9087C5dB93748d9c23881Aac8C0C54cfE553, true);
        pause();
    }

    function mint(address account, uint256 amount) public virtual onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        _mint(account, amount);
    }

    function claim(
        uint8 airdropType,
        uint256 amount,
        address inviter,
        uint256 rewards,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(!airdropClaimed[airdropType][_msgSender()], 'Claimed');
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(AIRDROP_CALL_HASH_TYPE, _msgSender(), amount, inviter, rewards))
        );
        require(
            airdropSigner[airdropType] != address(0) && ECDSA.recover(digest, v, r, s) == airdropSigner[airdropType],
            'Invalid signer'
        );
        require(airdropProvider[airdropType] != address(0), 'Invalid Provider');
        IERC20(address(this)).safeTransferFrom(airdropProvider[airdropType], _msgSender(), amount);
        if (inviter != address(0)) {
            IERC20(address(this)).safeTransferFrom(airdropProvider[airdropType], inviter, rewards);
        }
        airdropClaimed[airdropType][_msgSender()] = true;
        emit Airdrop(airdropType, _msgSender(), amount, inviter, rewards);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setTransferWhitelist(address owner, bool enable) public onlyOwner {
        transferWhitelist[owner] = enable;
    }

    function setAirdropProvider(uint8 airdropType, address provider) public onlyOwner {
        airdropProvider[airdropType] = provider;
    }

    function setAirdropSigner(uint8 airdropType, address signer) public onlyOwner {
        airdropSigner[airdropType] = signer;
    }

    function setTransferWhitelist(address[] calldata owners, bool enable) public onlyOwner {
        for (uint256 i; i < owners.length; i++) {
            setTransferWhitelist(owners[i], enable);
        }
    }

    function setTransferWhitelist(address[] calldata owners, bool[] calldata enables) public onlyOwner {
        require(owners.length == enables.length, 'length error');
        for (uint256 i; i < owners.length; i++) {
            setTransferWhitelist(owners[i], enables[i]);
        }
    }

    function setAirdrop(
        uint8 airdropType,
        address provider,
        address signer
    ) public onlyOwner {
        setTransferWhitelist(provider, true);
        setAirdropProvider(airdropType, provider);
        setAirdropSigner(airdropType, signer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || transferWhitelist[from], 'Token transfer while paused');
    }
}
