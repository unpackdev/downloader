// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IStandWithUkraine Contract to raise funds for helping Ukrainian civilians and army
 * @dev Allow a charity organization give non transferable nfts to contributors
 * @author Alex Encinas, Nazariy Dumanskyy, Sebastian Lujan, Lem Canady
 */
import "./Abstract1155Factory.sol";
import "./Strings.sol";

contract UkraineCharity is Abstract1155Factory {
    address public multisigWallet;
    uint256 public totalraised = 0 ether;
    // 1 = paused - 2 = active
    bool public paused = false;
    uint256[3] public nftsMaxSuplly = [5000, 130, 75];

    mapping(address => bool) public whitelist;
    mapping(address => bool) whitelistUsed;

    // @notice event emited when someone donates
    event Donation(address indexed _from, uint256 time, uint256 _value);

    // @notice event that fires when funds are withdrawn
    // @param to address that receives the contract balance
    // @param value value sent to the address
    event Withdrawn(address to, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _multisigWallet
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
        multisigWallet = _multisigWallet;
    }

    /**
    * @notice Donate eth and mint corresponding NFTs
    */
    function donate() public payable {
        if(whitelist[msg.sender] && !whitelistUsed[msg.sender]){
            whitelistDonation();
        } else {
            uint256 amountDonated = msg.value;
            uint256 tier = 0;
            if (amountDonated < 0.21 ether) {
                tier = 0;
            } else if (amountDonated < 0.51 ether) {
                tier = 1;
            } else {
                tier = 2;
            }
            mint(tier);
        }
    }

    /**
    * @notice Donate eth and mint corresponding NFTs for whitelisters
    */
    function whitelistDonation() private {
        whitelistUsed[msg.sender] = true;
        mint(2);
    }

    /**
    * @notice global mint function used for both whitelist and public mint
    *
    * @param _tier the tier of tokens that the sender will receive
    */
    function mint(uint256 _tier) private {
        require(!paused, "Contract is paused");
        require(msg.value >= 0.01 ether, "You must donate at least 0.01 ether");

        for (uint256 i = 0; i <= _tier; ++i){
            require(totalSupply(i) + 1 <= nftsMaxSuplly[i], "Max supply has been reached");
            _mint(msg.sender, (i), 1, "");
        }

        totalraised += msg.value;
        emit Donation(msg.sender, block.timestamp, msg.value);
    }

    /**
    * @notice giveaway nft of the selected tier to receiver
    *
    * @param nftTier set the nft to be minted
    * @param receiver address to receive the NFT
    */
    function giveAway(uint256 nftTier, address receiver) public onlyOwner {
        require(totalSupply(nftTier) + 1 <= nftsMaxSuplly[nftTier], "Max supply has been reached");
        _mint(receiver, nftTier, 1, "");
    }

    /**
    * @notice adds addresses into a whitelist
    *
    * @param addresses an array of addresses to add to whitelist
    */
    function setWhiteList(address[] calldata addresses ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    /**
    * @notice function to pause and unpause minting
    */
    function flipPause() external onlyOwner {
        paused = !paused;
    }

    /**
    * @notice withdraw all the funds to the multisig wallet tp later be donated to Ukrainian relief organizations
    */
    function withdrawAll() public payable onlyOwner {
        (bool succ, ) = multisigWallet.call{value: address(this).balance}("");
        require(succ, "transaction failed");
        emit Withdrawn(multisigWallet, address(this).balance);
    }

    /**
    * @notice change the supply of the selected tier
    *
    * @param _tier tier to change max supply for
    * @param _newMaxAmount Max supply to be assigned to the nft
    */
    function setMaxSupplly(uint256 _tier, uint256 _newMaxAmount)
        external
        onlyOwner
    {
        nftsMaxSuplly[_tier] = _newMaxAmount;
    }

    /**
    * @notice change all NFTs maxSupply
    *
    * @param _newSupplys array of new Supplys [tier1, tier2, tier3]
    */
    function batchSetMaxSupply(uint256[3] memory _newSupplys)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _newSupplys.length; ++i)
            nftsMaxSuplly[i] = _newSupplys[i];
    }

    /**
    * @notice returns true or false depending on if person is whitelist
    */
    function isWhitelisted() external view  returns (bool) {
        return whitelist[msg.sender] && !whitelistUsed[msg.sender];
    }

    /**
    * @notice returns the  uri for the selected NFT
    *
    * @param _id NFT id
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    Strings.toString(_id),
                    ".json"
                )
            );
    }
}
