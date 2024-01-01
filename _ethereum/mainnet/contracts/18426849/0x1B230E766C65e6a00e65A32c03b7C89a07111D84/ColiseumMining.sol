// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721A.sol";

/// @title ColiseumMiningAllocation
/// @dev This contract manages the allocation of USDC/USDT based on user's tier
contract ColiseumMiningAllocation is Ownable, ReentrancyGuard {
    // Interfaces for interacting with external token contracts
    IERC20 private usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC721A private soulbounds =
        IERC721A(0xCE37F9052E0f3f8E56887d8496FcD6cd6BeC06d0);
    IERC721A private stakedTokens =
        IERC721A(0xe07d6a4b99017aB280115f8711067871A4450640);
    IERC721A private vestedTokens =
        IERC721A(0x575D99d27ffF5974d608b7089404daDc9e291aca);
    IERC721A private normalTokens =
        IERC721A(0x08244aC887bb5d8d689315ce6335D742350133E6);

    /// @dev Structure to hold allocation information per user.
    struct Allocation {
        uint256 usdAllocated;
        uint256 allocationTimestamp;
    }

    /// @dev Counter to keep track of the total number of allocations.
    uint256 public totalAllocations;

    /// @dev Mapping from counter ID to user's address.
    mapping(uint256 => address) public idToAddress;

    /// @dev Mapping for tier 1.
    mapping(address => bool) public userAllowlisted;

    /// @dev Mapping of user address to their allocation information.
    mapping(address => Allocation) private allocations;

    constructor() Ownable(msg.sender) {
        userAllowlisted[0xb65e896544f2742E2F913E28eA00DaeaaF79C27c] = true;
        userAllowlisted[0x44F4e6c03B05bA04A08E2311040c85DC492493Ef] = true;
        userAllowlisted[0x2E12D1E5d81F9e4c50879Ee61C1483DF8160b2EE] = true;
        userAllowlisted[0xdF9092DcF734b7A036C9D42160E796541216Be3F] = true;
        userAllowlisted[0x0F615319D7CeeD5801faF6b13C9034DE9223a3eC] = true;
        userAllowlisted[0x1CB1c4b0A13B5E542cE3181C1dE845396e967C5a] = true;
        userAllowlisted[0xF0bF1C59ee9b78A2Ce5763165e1B6B24Cb35fD8A] = true;
        userAllowlisted[0x132371B1D1415C47C3441566c5bC2010364fD167] = true;
        userAllowlisted[0x88Fe79E3e74bB28faAF1532AaFF4d2cDDb594F74] = true;
        userAllowlisted[0x9e3DF23C284ceF828438a4143D6BdD950de54C82] = true;
        userAllowlisted[0xAedaD68EAfa16Dc0E4c231A02273A93d574323Ca] = true;
        userAllowlisted[0xB2030A19bC762Fe0E86aD8B5279865e2024dC6f7] = true;
        userAllowlisted[0x47664CD441143Be6553B6e7A57d8Fee9B7479B49] = true;
        userAllowlisted[0x241AbeFc7014e7c38831bbAf8800d54f15C64CC5] = true;
        userAllowlisted[0xB2a3041Dd3C35AeF30Dfc3B67096F67f7274146f] = true;
        userAllowlisted[0x8C0ccB514819DD2fb7888D7a9b1De3D75EA085bC] = true;
        userAllowlisted[0x68AD1Fa00cB9D499B73e85c6449766374463B6B2] = true;
        userAllowlisted[0x77410ab3B8775A8164c9BBBa92B64B341Be7b402] = true;
        userAllowlisted[0xB8ea3836bd58575360E3F012F781456291912ff1] = true;
        userAllowlisted[0x88B7bB15024D9cb9D506Bb21F3dC67f50294EB8C] = true;
        userAllowlisted[0x39f9A70a9a370793C6403b6796Bf49cE3ce9D65D] = true;
        userAllowlisted[0xbe5BE78a570126E6D66E0E5C211d4be03878a760] = true;
        userAllowlisted[0x1929e51F2151dF522F27C748b78a6F9F314A3138] = true;
        userAllowlisted[0xcCaE544F936daE9D7f588269BAD6F3F86DcdF2E4] = true;
        userAllowlisted[0x8cA64fb828A2Ad2C977A28A7e7a723Bf1b877Ee8] = true;
        userAllowlisted[0x5A432ecb3776d8bEEA169c31E5a460FFE24706Ab] = true;
        userAllowlisted[0x47664CD441143Be6553B6e7A57d8Fee9B7479B49] = true;
        userAllowlisted[0x9b4c11981D6d62a8b7d8007Dd1fa253F2Fc1f846] = true;
        userAllowlisted[0xEa2271D3484143F2A7e2A950A93e372906da8240] = true;
        userAllowlisted[0x0280991b064204C1118E13C071e5201bA870e20d] = true;
        userAllowlisted[0x0E84776F50D9C4b70020165edbA16b69e78E989C] = true;
        userAllowlisted[0x7E0e14b8Af95B8724eB9C6Fc6f7F38e55D0e197C] = true;
        userAllowlisted[0xD1CE3Ebb36C00E68ADd5E7C8343489D102283811] = true;
        userAllowlisted[0x1830A2e92ce6BF9EAc68E99692584544fF284024] = true;
        userAllowlisted[0xe1343b0557378b6Cd915C33AbBCB264d64D81BBe] = true;
        userAllowlisted[0x3bF165E64D853ACc3cCE25a23295eaDc69A03E19] = true;
        userAllowlisted[0xb65e896544f2742E2F913E28eA00DaeaaF79C27c] = true;
        userAllowlisted[0xa392D363B81620B0e78adF0f7e650F1bF3892E07] = true;
        userAllowlisted[0xbd5beaa49b793D35db39a79022ee70EBadB007bf] = true;
    }

    /// @dev Modifier to check the allocation eligibility based on tier.
    modifier checkAllocationLimit(uint256 amount) {
        uint256 userTier = getUserTier(msg.sender);
        require(userTier > 0, "Not eligible for allocation");
        if (userTier == 1) {
            _;
        } else if (
            userTier == 2 &&
            allocations[msg.sender].usdAllocated + amount * 1e6 <= 10000 * 1e6
        ) {
            _;
        } else if (
            userTier == 3 &&
            allocations[msg.sender].usdAllocated + amount * 1e6 <= 5000 * 1e6
        ) {
            _;
        } else if (
            userTier == 4 &&
            allocations[msg.sender].usdAllocated + amount * 1e6 <= 2500 * 1e6
        ) {
            _;
        } else if (
            userTier == 5 &&
            allocations[msg.sender].usdAllocated + amount * 1e6 <= 1000 * 1e6
        ) {
            _;
        } else {
            revert("Allocation limit exceeded");
        }
    }

    /// @notice Determines user tier based on their token holdings.
    /// @param user The address of the user.
    /// @return The tier of the user.
    function getUserTier(address user) public view returns (uint256) {
        uint256 staked = stakedTokens.balanceOf(user);
        uint256 vested = vestedTokens.balanceOf(user);
        uint256 normal = normalTokens.balanceOf(user);
        uint256 sbt = soulbounds.balanceOf(user);
        if (((staked + vested) > 2) || userAllowlisted[user] == true) {
            return 1;
        } else if (staked + vested + normal > 2) {
            return 2;
        } else if (staked + vested > 0) {
            return 3;
        } else if (normal > 0) {
            return 4;
        } else if (sbt == 1) {
            return 5;
        } else {
            return 0;
        }
    }

    /// @notice Allows users to allocate USDC or USDT.
    /// @param amount The amount of USDC or USDT to allocate.
    function allocate(
        uint256 amount
    ) external checkAllocationLimit(amount) nonReentrant {
        uint256 usdcBalance = usdc.balanceOf(msg.sender);
        if(amount == 0) revert ("Amount cannot be 0");
        if (usdcBalance >= amount * 1e6) {
            require(
                usdc.transferFrom(msg.sender, address(this), amount * 1e6),
                "USDC transfer failed"
            );
        } else {
            uint256 usdtBalance = usdt.balanceOf(msg.sender);

            require(usdtBalance >= amount * 1e6, "Insufficient USDT balance");

            require(
                usdt.transferFrom(msg.sender, address(this), amount * 1e6),
                "USDT transfer failed"
            );
        }

        // Check if this is a new allocation, if yes, increment counter and update mapping.
        if (allocations[msg.sender].usdAllocated == 0) {
            totalAllocations += 1;
            idToAddress[totalAllocations] = msg.sender;
        }
        allocations[msg.sender].usdAllocated += amount * 1e6;
        allocations[msg.sender].allocationTimestamp = block.timestamp;
    }

    /// @notice Allows owner to withdraw all USDC.
    function withdrawUSDC() external onlyOwner {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        require(usdc.transfer(msg.sender, usdcBalance), "USDC transfer failed");
    }

    /// @notice Allows owner to withdraw all USDT.
    function withdrawUSDT() external onlyOwner {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        require(usdt.transfer(msg.sender, usdtBalance), "USDC transfer failed");
    }

    /// @notice Allows owner to withdraw all USDC using transferFrom.
    function alternativeWithdrawUSDC() external onlyOwner {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        require(
            usdc.transferFrom(address(this), msg.sender, usdcBalance),
            "USDC transferFrom failed"
        );
    }

    /// @notice Allows owner to withdraw all USDT using transferFrom.
    function alternativeWithdrawUSDT() external onlyOwner {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        require(
            usdt.transferFrom(address(this), msg.sender, usdtBalance),
            "USDT transferFrom failed"
        );
    }

    /// @notice Allows owner to withdraw all ETH.
    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
    }

    /**
     * @notice Allows the owner to withdraw any ERC20 token.
     * @dev Only callable by the owner of the contract.
     * @param tokenAddress The address of the ERC20 token to be withdrawn.
     */
    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(
            token.transfer(msg.sender, tokenBalance),
            "Token transfer failed"
        );
    }

    /**
     * @notice Updates the address of the USDC token contract.
     * @dev Only callable by the owner of the contract.
     * @param _usdc The new address of the USDC token contract.
     */
    function setUSDC(address _usdc) external onlyOwner {
        usdc = IERC20(_usdc);
    }

    /**
     * @notice Updates the address of the USDT token contract.
     * @dev Only callable by the owner of the contract.
     * @param _usdt The new address of the USDT token contract.
     */
    function setUSDT(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    /**
     * @notice Updates the address of the Soulbounds token contract.
     * @dev Only callable by the owner of the contract.
     * @param _soulbounds The new address of the Soulbounds token contract.
     */
    function setSoulbounds(address _soulbounds) external onlyOwner {
        soulbounds = IERC721A(_soulbounds);
    }

    /**
     * @notice Updates the address of the StakedTokens token contract.
     * @dev Only callable by the owner of the contract.
     * @param _stakedTokens The new address of the StakedTokens token contract.
     */
    function setStakedTokens(address _stakedTokens) external onlyOwner {
        stakedTokens = IERC721A(_stakedTokens);
    }

    /**
     * @notice Updates the address of the VestedTokens token contract.
     * @dev Only callable by the owner of the contract.
     * @param _vestedTokens The new address of the VestedTokens token contract.
     */
    function setVestedTokens(address _vestedTokens) external onlyOwner {
        vestedTokens = IERC721A(_vestedTokens);
    }

    /**
     * @notice Updates the address of the NormalTokens token contract.
     * @dev Only callable by the owner of the contract.
     * @param _normalTokens The new address of the NormalTokens token contract.
     */
    function setNormalTokens(address _normalTokens) external onlyOwner {
        normalTokens = IERC721A(_normalTokens);
    }

    /// @notice Allows the contract to approve a user to transfer a specified amount of its tokens.
    /// @param tokenAddress The address of the token (USDT/USDC).
    /// @param user The address of the user to be approved.
    /// @param amount The amount of tokens to approve.
    function approveTokenTransfer(
        address tokenAddress,
        address user,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.approve(user, amount), "Token approval failed");
    }

    /// @notice Retrieves a user's allocation information.
    /// @param user The address of the user.
    /// @return Allocation structure containing the user's allocation info.
    function getAllocation(
        address user
    ) external view returns (Allocation memory) {
        return allocations[user];
    }

    /// @notice Retrieves the timestamp of allocation for a specific user.
    /// @param _user The address of the user.
    /// @return The timestamp of when the user made an allocation.
    function getAllocationTimestampOfUser(
        address _user
    ) external view returns (uint256) {
        return allocations[_user].allocationTimestamp;
    }

    /// @notice Retrieves the amount of USDC allocated by a specific user.
    /// @param _user The address of the user.
    /// @return The amount of USDC the user has allocated.
    function getAllocatedUSDOfUser(
        address _user
    ) external view returns (uint256) {
        return allocations[_user].usdAllocated;
    }

    /// @notice Adds multiple addresses to the allowlist.
    /// @param addresses An array of addresses to be added to the allowlist.
    function addToAllowlist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            userAllowlisted[addresses[i]] = true;
        }
    }

    /// @notice Removes multiple addresses from the allowlist.
    /// @param addresses An array of addresses to be removed from the allowlist.
    function removeFromAllowlist(
        address[] calldata addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            userAllowlisted[addresses[i]] = false;
        }
    }

    /// @notice Returns the allocation information of all users.
    /// @return An array of tuples, where each tuple contains an address and an Allocation struct.
    function getAllAllocations()
        external
        view
        returns (address[] memory, Allocation[] memory)
    {
        address[] memory allAddresses = new address[](totalAllocations);
        Allocation[] memory allAllocations = new Allocation[](totalAllocations);

        for (uint256 i = 1; i <= totalAllocations; i++) {
            address userAddress = idToAddress[i];
            allAddresses[i - 1] = userAddress;
            allAllocations[i - 1] = allocations[userAddress];
        }

        return (allAddresses, allAllocations);
    }
}
