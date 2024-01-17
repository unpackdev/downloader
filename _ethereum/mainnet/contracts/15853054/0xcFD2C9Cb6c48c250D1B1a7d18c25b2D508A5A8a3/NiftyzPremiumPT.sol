// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IMEMBERSHIP.sol";

/**
 * @title NiftyzPremiumPT
 */
contract NiftyzPremiumPT is ERC1155, Ownable, ReentrancyGuard {
    struct PassToken {
        uint256 id;
        uint256 price;
        uint256 supply;
        uint256 minted;
        address creator;
        uint256 timestamp;
        uint256 memberId;
        uint256 deadline;
    }

    string public metadataURI;
    mapping(string => PassToken) public passTokens;
    mapping(address => bool) public minters;
    mapping(uint256 => address) public creators;
    address _proxyAddress;
    address membershipContract;
    uint256 public _tokensCounter = 0;
    uint256 public contractFee = 3;
    uint256 public refereeFee = 20;
    uint256 public costPerUnlock = 0 ether;
    uint256 public costPerFreeMinting = 0.00005 ether;
    uint256 public availabilityWindow = 60;

    constructor(address _proxy, address _membership)
        ERC1155("https://api.niftyz.io/nfts/{id}")
    {
        metadataURI = "https://api.niftyz.io/nfts/{id}";
        _proxyAddress = _proxy;
        membershipContract = _membership;
    }

    /**
     * Admin functions to fix unlock fee
     */
    function fixUnlockFee(uint256 _newfee) public onlyOwner {
        costPerUnlock = _newfee;
    }

    /**
     * Admin functions to fix referee fee
     */
    function fixRefereesFee(uint256 _newfee) public onlyOwner {
        refereeFee = _newfee;
    }

    /**
     * Admin functions to fix availability window
     */
    function fixAvailabilityWindow(uint256 _newwindow) public onlyOwner {
        availabilityWindow = _newwindow;
    }

    /**
     * Admin functions to fix free minting fee
     */
    function fixFreeMintingFee(uint256 _newfee) public onlyOwner {
        costPerFreeMinting = _newfee;
    }

    /**
     * Admin functions to fix min unlock fee
     */
    function setURI(string memory _newuri) public onlyOwner {
        metadataURI = _newuri;
        _setURI(_newuri);
    }

    /**
     * Admin functions to set the contract fee
     */
    function setContracttFee(uint256 newfee) public onlyOwner {
        contractFee = newfee;
    }

    /**
     * Admin functions to set the proxy address
     */
    function setProxyAddress(address newproxy) public onlyOwner {
        _proxyAddress = newproxy;
    }

    /**
     * Admin functions to set the membership address
     */
    function setMembershipAddress(address newmembership) public onlyOwner {
        membershipContract = newmembership;
    }

    /**
     * Admin functions to set other minters for cross-chain minting
     */
    function setMinters(address minter, bool state) public onlyOwner {
        minters[minter] = state;
    }

    /*
        This method returns the prefix for validate the ownership
    */
    function getPrefix(string memory _metadata)
        public
        view
        returns (bytes memory)
    {
        require(passTokens[_metadata].timestamp > 0, "Can't find passtoken");
        uint256 created = passTokens[_metadata].timestamp;
        uint256 round = (block.timestamp - created) / availabilityWindow;
        return abi.encodePacked(_metadata, Strings.toString(round));
    }

    function mint(
        uint256 _membershipId,
        string memory _metadata,
        uint256 _supply,
        uint256 _price,
        uint256 _deadline
    ) public payable returns (uint256 tokenId) {
        require(
            msg.sender == _proxyAddress || minters[msg.sender] == true,
            "Only proxy address or minters can mint nfts"
        );
        require(passTokens[_metadata].id == 0, "This pass token exists yet");
        require(
            IMEMBERSHIP(membershipContract).nfts_type(_membershipId) > 0,
            "Membership must be premium, can't buy with free membership"
        );
        if (_price == 0) {
            uint256 totalFee = _supply * costPerFreeMinting;
            require(msg.value == totalFee, "Must send exact fee for airdrops");
        } else {
            require(msg.value == 0, "Can't send value if nfts have value");
        }
        _tokensCounter++;
        passTokens[_metadata].id = _tokensCounter;
        passTokens[_metadata].price = _price;
        passTokens[_metadata].timestamp = block.timestamp;
        passTokens[_metadata].supply = _supply;
        passTokens[_metadata].memberId = _membershipId;
        passTokens[_metadata].creator = IMEMBERSHIP(membershipContract).ownerOf(
            _membershipId
        );
        passTokens[_metadata].deadline = _deadline;
        return _tokensCounter;
    }

    function buy(string memory _metadata, address _receiver)
        public
        payable
        nonReentrant
    {
        require(passTokens[_metadata].id > 0, "This pass token doesn't exists");
        require(
            msg.value == passTokens[_metadata].price,
            "Wrong amount sent to buy"
        );
        require(
            passTokens[_metadata].minted < passTokens[_metadata].supply,
            "Can't mint more tokens"
        );
        if (passTokens[_metadata].deadline > 0) {
            require(
                block.timestamp <= passTokens[_metadata].deadline,
                "Can't mint after deadline"
            );
        }
        if (passTokens[_metadata].price > 0) {
            address referee = IMEMBERSHIP(membershipContract).referees(
                passTokens[_metadata].memberId
            );
            bool protocolSuccess;
            bool creatorSuccess;
            uint256 niftyz_fee = (msg.value * contractFee) / 100;
            uint256 creator_earn = msg.value - niftyz_fee;
            // Transfer fee to referee
            if (referee != address(0)) {
                bool refereeSuccess;
                uint256 referee_earn = (niftyz_fee * refereeFee) / 100;
                niftyz_fee = niftyz_fee - referee_earn;
                (refereeSuccess, ) = referee.call{value: referee_earn}("");
                require(refereeSuccess, "Send to referee failed");
            }
            (creatorSuccess, ) = passTokens[_metadata].creator.call{
                value: creator_earn
            }("");
            require(creatorSuccess, "Send to owner failed");
            (protocolSuccess, ) = owner().call{value: niftyz_fee}("");
            require(protocolSuccess, "Send to protocol failed");
        } else if (costPerUnlock > 0) {
            require(msg.value == costPerUnlock, "Must send minimum unlock fee");
            bool protocolSuccess;
            (protocolSuccess, ) = owner().call{value: costPerUnlock}("");
            require(protocolSuccess, "Send to creator failed");
        }
        passTokens[_metadata].minted++;
        _mint(_receiver, passTokens[_metadata].id, 1, bytes(""));
    }

    function withdrawFromVault() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw!");
        bool success;
        (success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw to admin failed");
    }
}
