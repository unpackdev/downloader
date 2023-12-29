// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface NonERCToken {
    function transfer(address recipient, uint256 amount) external;

 function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

contract NFTEscrow is ReentrancyGuard {
    mapping(string => Listing) public listings;
    mapping(string => bool) public requiresTokens;

    address payable public immutable owner;
    address payable public marketplaceAddress;
    address payable public makerAddress;    

    constructor() {
        owner = payable(msg.sender);
        marketplaceAddress = payable(0x2FEA74160714A5Cbc556A24fAe5cCa5F29a05337);
        makerAddress = payable(0x2FEA74160714A5Cbc556A24fAe5cCa5F29a05337);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Define an event
    event PaymentProcessed(
        string  listingGuid,
        address buyer,
        address seller,
        uint256 amount
    );
    event ListingCreated(
        address indexed sellerAddress,
        string  listingGuid,
        uint256 amount,
        string currency,
        uint256 marketplaceFee,
        uint256 makerFee
    );

    struct Listing {
        string  listingGuid;
        address payable sellerAddress;
        string buyerGuid;
        address tokenAddress;
        uint256 amount;
        string currency;
        uint256 marketplaceFee;
        uint256 makerFee;
        uint256 endDate;
        bool isPayed;
        bool isCompleted;
        bool IsTokenNonErc20;
    }

    function createListing(
        string memory listingGuid,
        string memory buyerGuid,
        uint256 amount,
        string memory currency,
        uint256 marketplaceFee,
        uint256 makerFee,
        uint256 endDate,
        address tokenAddress,
        uint256 IsTokenNonErc20
    ) public returns (bool) {
        require(bytes(buyerGuid).length > 0, "Invalid buyerAddress");
        require(amount > 0, "Invalid amount");
        require(bytes(currency).length > 0, "Invalid currency");
        require(bytes(listingGuid).length > 0,"Invalid listingGuid");
        require(
            keccak256(bytes(listings[listingGuid].listingGuid)) != keccak256(bytes(listingGuid)),
            "Listing already exists"
        );
        bool isNonERC20 = false;
        if(IsTokenNonErc20 == 1){
            isNonERC20 = true;
        }

        if (tokenAddress != address(0)) {
            requiresTokens[listingGuid] = true;
        }

        listings[listingGuid] = Listing({
            listingGuid:listingGuid,
            sellerAddress: payable(msg.sender),
            buyerGuid: buyerGuid,
            amount: amount,
            currency: currency,
            marketplaceFee: marketplaceFee,
            makerFee:makerFee,
            endDate:endDate,
            isPayed: false,
            isCompleted: false,
            tokenAddress: tokenAddress,
            IsTokenNonErc20: isNonERC20
        });

        // Emit the event
        emit ListingCreated(
            msg.sender,
            listingGuid,
            amount,
            currency,
            marketplaceFee,
            makerFee
        );  
        return true;
    }
    

    // function to delete listing
    function removeListing(string memory listingGuid) public onlyOwner returns (bool) {
        require(bytes(listings[listingGuid].listingGuid).length > 0, "Listing does not exist");
        delete listings[listingGuid];
        return true;
    }

    // function to pay for Listing Id from buyer to seller
    function paySeller(
        string memory listingGuid,
        string memory buyerGuid,
        string memory currency
    ) public payable returns (bool) {
        Listing storage listing = listings[listingGuid];
        require(keccak256(bytes(listing.buyerGuid)) == keccak256(bytes(buyerGuid)), "You are not a buyer");
        require(listing.isCompleted == false, "Listing already completed");
        require(keccak256(bytes(listing.listingGuid)) == keccak256(bytes(listingGuid)),"Not the correct guid");
        require(
            keccak256(abi.encodePacked(listing.currency)) ==
                keccak256(abi.encodePacked(currency)),
            "Invalid currency"
        );
        require(block.timestamp < listing.endDate,"Listing Expired");

        if (requiresTokens[listingGuid]) {
            if (listing.IsTokenNonErc20) {
                NonERCToken token = NonERCToken(listing.tokenAddress);
                token.transferFrom(msg.sender, address(this), listing.amount);
                token.transfer(marketplaceAddress, listing.marketplaceFee);
                if(listing.makerFee > 0){
                    token.transfer(makerAddress, listing.makerFee);
                }
                token.transfer(
                    listing.sellerAddress,
                    listing.amount - listing.marketplaceFee - listing.makerFee
                );
            } else {
                // Retrieve the ERC20 token contract
                IERC20 token = IERC20(listing.tokenAddress);
                
                  require(
                    token.transferFrom(
                        msg.sender,
                        address(this),
                        listing.amount
                    ),
                    "Token transfer failed"
                );
                require(
                    token.transfer(marketplaceAddress, listing.marketplaceFee),
                    "Token transfer failed"
                );
                require(
                    token.transfer(
                        listing.sellerAddress,
                        listing.amount - listing.marketplaceFee - listing.makerFee
                    ),
                    "Token transfer failed"
                );
            }
        } else {
            require(
                msg.value == listing.amount,
                string.concat("Incorrect amount to buy listing:",uint2str(listing.amount),"-", uint2str(msg.value)) 
            );           
            listing.sellerAddress.transfer(listing.amount - listing.marketplaceFee - listing.makerFee);
            marketplaceAddress.transfer(listing.marketplaceFee);
            makerAddress.transfer(listing.makerFee);
        }

        //listing.ownerof = msg.sender;
        listing.isPayed = true;
        listing.isCompleted = true;

        emit PaymentProcessed(
            listing.listingGuid,
            msg.sender,
            listing.sellerAddress,
            listing.amount
        );

        return true;
    }
    function addressToString(address _addr) public pure returns(string memory) 
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

     function uint2str(
        uint256 _i
        )
        internal
        pure
        returns (string memory str)
        {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    // Function to check token balance
    function getTokenBalance(
        address tokenAddress,
        address accountAddress
    ) external view returns (uint256) {
        uint256 balance = 0;
        if (isERC20Token(IERC20(tokenAddress))) {
            IERC20 token = IERC20(tokenAddress);
            balance = token.balanceOf(accountAddress);
        } else {
            NonERCToken token = NonERCToken(tokenAddress);
            balance = token.balanceOf(accountAddress);
        }
        return balance;
    }

    function readListing(string memory listingGuid) public view returns (Listing memory) {
        return listings[listingGuid];
    }

    // Function to check coin balance
    function getCoinBalance(
        address walletAddress
    ) public view returns (uint256) {
        return walletAddress.balance;
    }

    // Function to withdraw or transfer tokens to another address
    function withdrawTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (isERC20Token(IERC20(tokenAddress))) {
            // Retrieve the ERC20 token contract
            IERC20 token = IERC20(tokenAddress);
            // Ensure the contract has enough balance
            require(
                token.balanceOf(address(this)) >= amount,
                "Insufficient balance"
            );
            // Transfer tokens to the specified address
            require(token.transfer(to, amount), "Token transfer failed");
        } else {
            // Retrieve the NON ERC20 token contract
            NonERCToken token = NonERCToken(tokenAddress);
            // Ensure the contract has enough balance
            require(
                token.balanceOf(address(this)) >= amount,
                "Insufficient balance"
            );
            token.transfer(to, amount);
        }
    }

    // Function to check if a token supports the ERC20 interface
    function isERC20Token(IERC20 token) public view returns (bool) {
        try token.totalSupply() returns (uint256) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }
}