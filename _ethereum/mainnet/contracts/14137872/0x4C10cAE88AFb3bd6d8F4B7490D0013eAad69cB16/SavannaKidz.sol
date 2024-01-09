// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./OpenTown.sol";

contract SavannaKidz is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_RESERVED = 200;
    uint256 private constant MAX_PER_MINT = 20;

    // ERC721Metadata
    string private baseURI;

    // Reserve, Presale, Sale
    uint256 public reserved = 200;
    uint256 public price = 0.05 ether;
    bool public isPresaleActive;
    bool public isSaleActive;

    // $OPENTOWN
    uint256 private constant REWARD_PERIOD_END = 2011132800; // 2033-09-24 00:00
    uint256 private constant INITIAL_REWARD = 3000 ether;
    uint256 private constant DAILY_REWARD = 4 ether;

    OpenTown public openTownContract;

    // Token reward logic inspired by:
    // https://etherscan.io/address/0x57a204aa1042f6e66dd7730813f4024114d74f37#code
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private lastUpdate;

    // Wallets
    address payable public famWallet;

    constructor(string memory initBaseURI) ERC721("Savanna Kidz", "SK") {
        baseURI = initBaseURI;
    }

    // ERC721Metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Reserve
    function reserve(address[] calldata addresses, uint256 amount)
        external
        onlyOwner
    {
        uint256 totalAmount = addresses.length * amount;
        require(totalAmount > 0, "Need at least 1 token");
        require(totalAmount <= MAX_PER_MINT, "20 tokens per call max");
        require(totalAmount <= reserved, "Exceeds reserved supply");

        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Invalid address");
            uint256 supply = totalSupply();

            for (uint256 j = 1; j <= amount; j++) {
                _safeMint(addresses[i], supply + j);
            }
            updateRewardOnMint(addresses[i], amount);
        }

        reserved -= totalAmount;
    }

    // Presale
    function togglePresale() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function presaleMint(
        uint8 mintAmount,
        uint8 maxMintAmount,
        bytes memory signature
    ) public payable {
        uint256 supply = totalSupply();
        uint256 userBalance = balanceOf(msg.sender);

        require(isPresaleActive, "Presale is not active.");
        require(
            verify(msg.sender, maxMintAmount, signature),
            "User/amount not authorized for presale."
        );
        require(mintAmount <= MAX_PER_MINT, "20 tokens per mint max");
        require(
            supply + mintAmount <= MAX_SUPPLY - reserved,
            "Exceeds maximum supply"
        );
        require(
            userBalance + mintAmount <= maxMintAmount,
            "Exceeds maximum allowance"
        );
        require(
            msg.value >= price * mintAmount,
            "Ether amount sent is not correct"
        );

        for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        updateRewardOnMint(msg.sender, mintAmount);
    }

    // Signature verification implementation inspired by
    // https://solidity-by-example.org/signature/
    function getMessageHash(address user, uint256 maxMintAmount)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), user, maxMintAmount));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function verify(
        address user,
        uint256 maxMintAmount,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(user, maxMintAmount);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == owner();
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // Sale
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mint(uint256 mintAmount) external payable {
        uint256 supply = totalSupply();
        require(isSaleActive, "Sale is not active");
        require(mintAmount <= MAX_PER_MINT, "20 tokens per mint max");
        require(
            supply + mintAmount <= MAX_SUPPLY - reserved,
            "Exceeds maximum supply"
        );
        require(
            msg.value >= price * mintAmount,
            "Ether amount sent is not correct"
        );

        for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        updateRewardOnMint(msg.sender, mintAmount);
    }

    // Transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        updateReward(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        updateReward(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    // $OPENTOWN
    function setOpenTown(address openTown) external onlyOwner {
        openTownContract = OpenTown(openTown);
    }

    function getTotalClaimable(address user) external view returns (uint256) {
        uint256 time = min(block.timestamp, REWARD_PERIOD_END);
        uint256 userTimer = lastUpdate[user];
        return rewards[user] + pendingReward(user, time, userTimer);
    }

    function getReward() external {
        updateReward(msg.sender, address(0));

        uint256 reward = rewards[msg.sender];

        if (reward > 0) {
            rewards[msg.sender] = 0;
            openTownContract.getReward(msg.sender, reward);
        }
    }

    function updateRewardOnMint(address user, uint256 amount) internal {
        uint256 time = min(block.timestamp, REWARD_PERIOD_END);
        uint256 userTimer = lastUpdate[user];
        uint256 mintGrant = amount * INITIAL_REWARD;

        if (userTimer > 0) {
            rewards[user] += pendingReward(user, time, userTimer) + mintGrant;
        } else {
            rewards[user] += mintGrant;
        }

        lastUpdate[user] = time;
    }

    function updateReward(address from, address to) internal {
        uint256 time = min(block.timestamp, REWARD_PERIOD_END);
        uint256 timerFrom = lastUpdate[from];

        if (timerFrom > 0) {
            rewards[from] += pendingReward(from, time, timerFrom);
        }

        if (timerFrom != REWARD_PERIOD_END) {
            lastUpdate[from] = time;
        }

        if (to != address(0)) {
            uint256 timerTo = lastUpdate[to];

            if (timerTo > 0) {
                rewards[from] += pendingReward(to, time, timerTo);
            }

            if (timerTo != REWARD_PERIOD_END) {
                lastUpdate[to] = time;
            }
        }
    }

    function pendingReward(
        address user,
        uint256 time,
        uint256 userTimer
    ) internal view returns (uint256) {
        return (balanceOf(user) * DAILY_REWARD * (time - userTimer)) / 86400;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Wallets
    function setFamWallet(address payable fam) external onlyOwner {
        famWallet = fam;
    }

    function withdraw() external onlyOwner {
        require(famWallet != address(0), "FAM address not set");

        // Send 50% of funds to FAM
        (bool famSuccess, ) = famWallet.call{
            value: (address(this).balance * 50) / 100
        }("");
        require(famSuccess, "Failed to send Ether to FAM");

        // Send the other 50% to owner
        (bool ownerSuccess, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(ownerSuccess, "Failed to send Ether to owner");
    }
}
