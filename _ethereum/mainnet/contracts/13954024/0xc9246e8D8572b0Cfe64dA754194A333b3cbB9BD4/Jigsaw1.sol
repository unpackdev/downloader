// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Counters.sol";

interface IJigsaw1BadgeContract {
    function mintFinalPicture(address _account) external ;
    function addMinter( address _account) external ;
    function removeMinter( address _account) external ;
    function bulkMintFinalPicture(address[] memory _accounts) external;
}

contract Jigsaw1 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];
    using Strings for uint256;
    using ECDSA for bytes32;
    using SafeMath for uint256;

    /// @notice Total Private Sale
    uint256 public constant jigsawPresale = 750;
    /// @notice Total Fiat Sale
    uint256 public constant jigsawFiat = 2000;
    /// @notice Total Supply
    uint256 public constant jigsawTotal = 5632;

    /// @notice allow users to mint up to 2 per wallet during whitelisted sale
    uint256 public constant MAX_WHITELISTED_MINTED_NUMBER = 2;
    /// @notice allow users to mint up to 10 per wallet
    uint256 public constant MAX_MINTED_NUMBER = 10;
    /// @notice Token has been minted to the address
    mapping(address => uint256) public hasMinted;
    /// @notice Address can mint the private sale i.e. whitelisted addresses
    mapping(address => bool) public privateSaleEntries;

    /// @notice Token Price
    uint256 public price = 0.11 ether;
    
    /// below list of properties related to final nft mint on claimReward.
    /// @notice maximum final puzzle picture count
    address public finalBadgeContractAddress;
    uint256 public MAX_FINAL_PUZZLE_PICTURE_NUMBER;
    address[] public finalOwners;
    uint256[][] public finalOwnersTokenIds ;
    uint256 public finalPictureTokenIds;
    mapping(address => uint256) public hasReceivedFinalPictureNft;
    string private _tokenFinalPictureBaseURI = '';

    /// @notice Token Base URI
    string private _tokenBaseURI = '';

    /// @notice Community Pool - 20% of the mint fee
    uint256 public constant communityRatio = 2000;
    /// @notice Community Merkle Root
    bytes32 public communityRoot;
    /// @notice Community Reward Claimed
    mapping(address => bool) public isClaimedCommunity;

    /// @notice Charity Pool - 20% of the mint fee
    uint256 public constant charityRatio = 2000;

    /// @notice Charity, Vote amount, Pool address, Reward ratio
    struct CharityInfo {
        bytes32 charity;
        uint256 vote;
        address payable pool;
        uint256 ratio;
    }

    /// @notice Charity vote infos
    CharityInfo[] public charityInfos;

    /// @notice Bored Puzzles - 60% of the mint fee
    uint256 public constant boredRatio = 6000;
    /// @notice Bored Puzzles Address
    address payable public boredAddress;

    /// @notice Count of Public Saled Tokens
    uint256 public publicCounter;
    /// @notice Count of Fiat Saled Tokens
    uint256 public fiatCounter;
    /// @notice fiatFee is the amount of ETH received on fiat sale
    uint256 public fiatFee;
    /// @notice Count of Private Saled Tokens
    uint256 public privateCounter;
    /// @notice Start timestamp for the Private Sale
    uint256 public privateSaleBegin = 9999999990;
    /// @notice Start timestamp for the Fiat Sale
    uint256 public fiatSaleBegin = 9999999991;
    /// @notice Start timestamp for the Public Sale
    uint256 public publicSaleBegin = 9999999992;

    /// @notice Game period
    uint256 public constant period = 5 days;
    /// @notice Game Started At
    uint256 public startedAt;
    /// @notice Game Ended At
    uint256 public endedAt;

    /// @notice Editable for Token Base URI
    bool public editable;

    /// @notice Total Fee
    uint256 public totalFee;
    /// @notice Estimated Gas for Mint
    uint256 public estimatedGasForMint = 0;

    /// claim you nft properties

    /// @notice Events
    event StartGame(uint256 indexed at);
    event EndGame(uint256 indexed at);
    event UploadedCommunityRoot();
    event ClaimedCommunity(address indexed account, uint256 amount);
    event ClaimedCommunityNFT(address indexed account, uint256 tokenId);

    event ClaimedCharity(
        bytes32 indexed charity,
        address indexed pool,
        uint256 amount
    );

    modifier onlyEditable() {
        require(editable, 'METADATA_FUNCTIONS_LOCKED');
        _;
    }

    constructor() ERC721('Bored Puzzles Jigsaw1', 'BPJ1') {
        editable = true;
    }

    function safeTransferETH(address payable _to, uint256 _amount)
        internal
        returns (bool success)
    {
        if (_amount > address(this).balance) {
            (success, ) = _to.call{value: address(this).balance}('');
        } else {
            (success, ) = _to.call{value: _amount}('');
        }
    }

    ///--------------------------------------------------------
    /// Public Sale
    /// Fiat Sale
    /// Private Sale
    ///--------------------------------------------------------

    /**
     * @notice Mint on Public Sale
     */
    function mint(uint256 _amount) external payable {
        require(
            block.timestamp >= publicSaleBegin || fiatCounter >= jigsawFiat,
            'ER: Public sale is not started'
        );
        require(totalSupply()+ _amount <= jigsawTotal, 'ER: The sale is sold out');
        require(
            hasMinted[msg.sender] + _amount <= MAX_MINTED_NUMBER,
            'ER: You can not mint more than maximum allowed tokens'
        );

        // Calculate Mint Fee with Gas Substraction
        uint256 mintFee = price*_amount - tx.gasprice * estimatedGasForMint;

        require(mintFee <= msg.value, 'ER: Not enough ETH');

        /// @notice Return any ETH to be refunded
        uint256 refund = msg.value - mintFee;
        if (refund > 0) {
            require(
                safeTransferETH(payable(msg.sender), refund),
                'ER: Return any ETH to be refunded'
            );
        }

        publicCounter += _amount;
        totalFee += mintFee;
        hasMinted[msg.sender] += _amount;
        for(uint256 i = 0 ; i < _amount ; i += 1){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    /**
     * @notice Admin can mint to the users for Fiat Sale
     * @param _to Users wallet addresses
     */
    function safeMint(address[] memory _to, uint256[] memory _nftCount)
        external
        payable
        onlyOwner{
        require(
            block.timestamp >= fiatSaleBegin || privateCounter >= jigsawPresale,
            'ER: Fiat sale is not started'
        );
        require(
            block.timestamp < publicSaleBegin,
            'ER: Fiat sale is currently closed'
        );

        uint256 totalAccounts = _to.length;

        for (uint256 i = 0; i < totalAccounts; i++) {
            address to = _to[i];

            uint256 totalTokensToMint = _nftCount[i];
            //minting multiple tokens for individual
            for (uint256 j = 0; j < totalTokensToMint; j++) {
                if (hasMinted[to] < MAX_MINTED_NUMBER) {
                    require(
                        totalSupply() < jigsawTotal,
                        'ER: The sale is sold out'
                    );
                    require(
                        fiatCounter < jigsawFiat,
                        'ER: Not enough Jigsaws left for the fiat sale'
                    );

                    fiatCounter++;
                    hasMinted[to] += 1;
                    //as tx.gasprice is price for the 
                    uint256 mintFee = price - tx.gasprice * estimatedGasForMint;
                    totalFee += mintFee;
                    fiatFee += price;
                    _safeMint(to, totalSupply() + 1);
                } else break;
            }
        }
        // totalFee -= tx.gasprice * estimatedGasForMint;
        // totalFee += msg.value;
    }

    /**
     * @notice Mint on Private Sale i.e. during whitelist sale period
     */
    function privateMint(uint256 _amount) external payable {
        require(
            block.timestamp >= privateSaleBegin,
            'ER: Private sale is not started'
        );
        require(
            block.timestamp < fiatSaleBegin,
            'ER: Private sale is currently closed'
        );
        require(
            privateSaleEntries[msg.sender],
            'ER: You are not qualified for the presale'
        );
        require(totalSupply() + _amount <= jigsawTotal, 'ER: The sale is sold out');
        require(
            privateCounter + _amount <= jigsawPresale,
            'ER: Not enough Jigsaws left for the presale'
        );
        require(
            hasMinted[msg.sender] + _amount <= MAX_WHITELISTED_MINTED_NUMBER,
            'ER: You have already minted maximum for whitelisted sale'
        );

        // Calculate Mint Fee with Gas Substraction
        uint256 mintFee = price*_amount - tx.gasprice * estimatedGasForMint;

        require(mintFee <= msg.value, 'ER: Not enough ETH');

        /// @notice Return any ETH to be refunded
        uint256 refund = msg.value - mintFee;
        if (refund > 0) {
            require(
                safeTransferETH(payable(msg.sender), refund),
                'ER: Return any ETH to be refunded'
            );
        }

        privateCounter += _amount;
        totalFee += mintFee;
        hasMinted[msg.sender] += _amount;
        for(uint256 i = 0 ; i < _amount ; i += 1){
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    ///--------------------------------------------------------
    /// Insert private buyers
    /// Remove private buyers
    ///--------------------------------------------------------

    /**
     * @notice Admin can insert the addresses to mint the presale
     * @param privateEntries Addresses for the presale
     */
    function insertPrivateSalers(address[] calldata privateEntries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < privateEntries.length; i++) {
            require(privateEntries[i] != address(0), 'ER: Null Address');
            require(
                !privateSaleEntries[privateEntries[i]],
                'ER: Duplicate Entry'
            );

            privateSaleEntries[privateEntries[i]] = true;
        }
    }

    /**
     * @notice Admin can stop the addresses to not mint the presale
     * @param privateEntries Addresses for the non-presale
     */
    function removePrivateSalers(address[] calldata privateEntries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < privateEntries.length; i++) {
            require(privateEntries[i] != address(0), 'ER: Null Address');

            privateSaleEntries[privateEntries[i]] = false;
        }
    }

    ///--------------------------------------------------------
    /// Sales Begin Timestamp
    /// Start Game
    /// End Game
    ///--------------------------------------------------------

    /**
     * @notice Admin can set the privateSaleBegin, fiatSaleBegin, publicSaleBegin timestamp
     * @param _privateSaleBegin Timestamp to begin the private sale
     * @param _fiatSaleBegin Timestamp to begin the fiat sale
     * @param _publicSaleBegin Timestamp to begin the public sale
     */
    function setSalesBegin(
        uint256 _privateSaleBegin,
        uint256 _fiatSaleBegin,
        uint256 _publicSaleBegin) external onlyOwner {
        require(
            _privateSaleBegin < _fiatSaleBegin &&
                _fiatSaleBegin < _publicSaleBegin,
            'ER: Invalid timestamp for sales'
        );

        privateSaleBegin = _privateSaleBegin;
        fiatSaleBegin = _fiatSaleBegin;
        publicSaleBegin = _publicSaleBegin;
    }

    function getSalesBeginTimestamp()
        external
        view
        returns (uint256,uint256,uint256,uint256) {
        return (
            privateSaleBegin,
            fiatSaleBegin,
            publicSaleBegin,
            block.timestamp
        );
    }

    /**
     * @notice Admin can start the game
     * @param _boredAddress Bored Puzzles address
     */
    function startGame(address payable _boredAddress) external onlyOwner {
        require(
            _boredAddress != address(0),
            'ER: Invalid Bored Puzzle address'
        );
        require(startedAt == 0, 'ER: Game is already began');

        startedAt = block.timestamp;
        boredAddress = _boredAddress;

        uint256 amount = ((totalFee * boredRatio) -fiatFee) / 1e4;
        require(
            safeTransferETH(boredAddress, amount),
            'ER: ETH transfer to Bored Puzzles failed'
        );

        emit StartGame(startedAt);
    }

    /**
     * @notice Admin can end the game
     */
    function endGame() external onlyOwner {
        require(startedAt > 0, 'ER: Game is not started yet');
        require(endedAt == 0, 'ER: Game is has already ended');

        endedAt = block.timestamp;
        (address[] memory _owners, uint256[][] memory _tokenIds) = grabAllOwners();
        setSnapshotFinalPlayers(_owners, _tokenIds);
        emit EndGame(endedAt);

        airdropFinalPictureToFinalOwners();
    }

    function setSnapshotFinalPlayers(address[] memory _owners, uint256[][] memory _tokenIds) internal {
        MAX_FINAL_PUZZLE_PICTURE_NUMBER  = _owners.length;
        finalOwners = _owners;
        finalOwnersTokenIds = _tokenIds;
    }

    function getSnapshotFinalPlayers() public view returns (address[] memory, uint256[][] memory) {
        return (finalOwners, finalOwnersTokenIds);
    }

    ///--------------------------------------------------------
    /// Upload Coummunity Merkle Root
    /// Claim the Community Reward
    /// Upload Charity Vote Result
    ///--------------------------------------------------------

    /**
     * @notice Admin can upload the Community root
     * @param _communityRoot Community Distribution Merkle Root
     */
    function uploadCommunityRoot(bytes32 _communityRoot) external onlyOwner {
        require(endedAt > 0, 'ER: Game is not ended yet');
        require(
            communityRoot == bytes32(0),
            'ER: Community Root is already set'
        );
        communityRoot = _communityRoot;
        emit UploadedCommunityRoot();
    }

    function setGameStartandEndTime(
        uint256 _startedAt,
        uint256 _endedAt,
        uint256 _totalFee ) public onlyOwner {
        startedAt = _startedAt;
        endedAt = _endedAt;
        totalFee = _totalFee;
    }

    /**
     @notice Calculates communityAmount and charityAmount, used in internal calls.
    */
    function getCommunityAmount()
        public
        view
        returns (uint256 _communityAmount, uint256 _charityAmount){
        uint256 delayPeriod;

        if ((endedAt - startedAt) > period) {
            delayPeriod = (endedAt - startedAt) - period;
        }
        uint256 delaySeconds = delayPeriod % 1 days;
        uint256 delayDays = delayPeriod / 1 days;

        uint256 transferenceAmount;

        uint256 tempCommunityAmount = (totalFee * communityRatio) / 1e4;
        if (delayPeriod >= 0 days && delayPeriod < 1 days) {
            transferenceAmount =
                (totalFee * communityRatio * delaySeconds * 500) /
                (1 days * 1e8);
        } else if (delayPeriod >= 1 days && delayPeriod < 2 days) {
            transferenceAmount = (totalFee * communityRatio * 500) / (1e8);
            transferenceAmount +=
                (totalFee * communityRatio * delaySeconds * 1000) /
                (1 days * 1e8);
        } else {
            transferenceAmount = (totalFee * communityRatio * 500) / (1e8);
            transferenceAmount += (totalFee * communityRatio * 1000) / (1e8);
            transferenceAmount +=
                (totalFee *
                    communityRatio *
                    1500 *
                    ((delayDays.sub(2) * 86400).add(delaySeconds))) /
                (1 days * 1e8);
        }

        uint256 communityAmount = tempCommunityAmount - transferenceAmount;
        uint256 charityAmount = (totalFee * (communityRatio + charityRatio)) /
            1e4 -
            communityAmount;

        return (communityAmount, charityAmount);
    }
 
    /**
     @notice Claim the community reward
     @param _account Receiver address
     @param _percent Reward percent
     @param _proof Merkle proof data
     */
    function claimCommunity(
        address _account,
        uint256 _percent,
        bytes32[] memory _proof
    ) external {
        require(endedAt > 0, 'ER: Game is not ended yet');
        require(!isClaimedCommunity[_account], 'ER: Community claimed already');
        bytes32 leaf = keccak256(abi.encodePacked(_account, _percent));
        require(MerkleProof.verify(_proof, communityRoot, leaf), "ER: Community claim wrong proof");

        (uint256 communityAmount, ) = getCommunityAmount();
        uint256 amount = (communityAmount * _percent) / 1e4;
        isClaimedCommunity[_account] = true;
        if (safeTransferETH(payable(_account), amount)) {
            emit ClaimedCommunity(_account, amount);
        }
    }

    /**
    @notice Mint final pictures to owners on endGame.
    */
    function airdropFinalPictureToFinalOwners() internal {
        require(endedAt > 0, 'ER: Game has not ended yet');
        // require(isAccountWhitelisted(_account), 'ER: You are not authorized to get final picture NFT');

        require(
            finalPictureTokenIds + finalOwners.length <= MAX_FINAL_PUZZLE_PICTURE_NUMBER,
            'ER: Final puzzle pictures exceeded quota'
        );
        finalPictureTokenIds += MAX_FINAL_PUZZLE_PICTURE_NUMBER ;
        IJigsaw1BadgeContract badgeContract = IJigsaw1BadgeContract(finalBadgeContractAddress);
        badgeContract.bulkMintFinalPicture(finalOwners);
    }

    //it checks if account is whitelisted to get the final nft picture nft on claim rewards
    function isAccountWhitelisted(address _account) internal view returns (bool) {
        for(uint256 i = 0; i < finalOwners.length ; i++){
            if(finalOwners[i] == _account) return true;
        }
        return false;
    }

    /**
     * @notice Admin can upload the Charity vote result
     * @param _charityInfos Charity vote result
     */
    function uploadCharityInfos(CharityInfo[] memory _charityInfos)
        external
        onlyOwner {
        require(endedAt > 0, 'ER: Game is not ended yet');
        require(_charityInfos.length > 0, 'ER: Invalid Charity Info');
        require(charityInfos.length == 0, 'Er: Charity Info is already set');

        (, uint256 charityAmount) = getCommunityAmount();
        uint256 maxVote;
        uint256 count;
        uint256 length = _charityInfos.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 vote = _charityInfos[i].vote;
            if (maxVote == vote) {
                count++;
            } else if (maxVote < vote) {
                maxVote = vote;
                count = 1;
            }
        }

        for (uint256 i = 0; i < length; i++) {
            CharityInfo memory info = _charityInfos[i];
            if (info.vote == maxVote) {
                info.ratio = 1e4 / count;

                uint256 amount = charityAmount / count;
                if (safeTransferETH(info.pool, amount)) {
                    emit ClaimedCharity(info.charity, info.pool, amount);
                }
            } else {
                info.ratio = 0;
            }
            charityInfos.push(info);
        }
    }

    ///--------------------------------------------------------
    /// Token Editable
    /// Token BaseURI
    /// Token Mint Gas
    ///--------------------------------------------------------

     /**
     * @notice Admin can set price of nft
     * @param _amount is latest price of nft
     */
    function setPrice(uint256 _amount) external onlyOwner {
        price = _amount;
    }

    /**
     * @notice Admin can enable/disable the editable
     * @param _editable Can Edit
     */
    function setEditable(bool _editable) external onlyOwner {
        editable = _editable;
    }

    /**
     * @notice Admin can set the Token Base URI but it should be editable
     * @param _URI Token Base URI
     */
    function setBaseURI(string memory _URI) external onlyOwner onlyEditable {
        _tokenBaseURI = _URI;
    }


    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    // get baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @notice Admin can set finalBadgeContractAddress
     * @param _add as address of finalBadgeContractAddress
     */
    function setFinalBadgeContractAddress(address _add)
        external
        onlyOwner
    {
        finalBadgeContractAddress = _add;
    }

    /**
     * @notice Admin can update the estimated Gas for Mint
     * @param _estimatedGasForMint Can Edit
     */
    function setEstmatedGasForMint(uint256 _estimatedGasForMint)
        external
        onlyOwner
    {
        estimatedGasForMint = _estimatedGasForMint;
    }

    ///--------------------------------------------------------
    /// View functions
    ///--------------------------------------------------------

    /**
     * @notice Each token's URI
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), 'Cannot query non-existent token');
        if (tokenId <= jigsawTotal)
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), '.json')
                );
        else return 'ER: Not a valid token';
    }

    /**
     * @notice Get list of owners and corresponding list of owner tokens
     */
    function grabAllOwners()
        public
        view
        returns (address[] memory, uint256[][] memory)
    {
        uint256 ts = totalSupply();
        address[] memory owners = new address[](ts);
        uint256[][] memory tokens = new uint256[][](ts);

        //NOTE: current func might fail if used dynamic generated long tokenIds
        // bool[] memory tempTokenIds = new bool[](jigsawTotal + MAX_FINAL_PUZZLE_PICTURE_NUMBER);
        bool[] memory tempTokenIds = new bool[](jigsawTotal);
        uint256 userCounterIndex = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            uint256 tempTokenId = tokenByIndex(i);
            address tempOwner = ownerOf(tempTokenId);
            uint256 bal = balanceOf(tempOwner);
            if (tempTokenIds[tempTokenId] != true) {
                uint256[] memory tempIds = new uint256[](bal);
                for (uint256 j = 0; j < bal; j++) {
                    uint256 tId = tokenOfOwnerByIndex(tempOwner, j);
                    tempIds[j] = tId;
                    tempTokenIds[tId] = true;
                }
                owners[userCounterIndex] = tempOwner;
                tokens[userCounterIndex] = tempIds;
                userCounterIndex += 1;
            }
        }

        address[] memory owners1 = new address[](userCounterIndex);
        uint256[][] memory tokens1 = new uint256[][](userCounterIndex);
        for (uint256 i = 0; i < userCounterIndex; i++) {
            owners1[i] = owners[i];
            tokens1[i] = tokens[i];
        }
        return (owners1, tokens1);
    }

    //owner can withdraw the amount from the SC balance. pass 500 as args for 5%.
    function withdraw(address _address, uint256 percentage) external onlyOwner {
        // require(startedAt > 0, 'ER: Cant withdraw as game has not started yet');
        uint256 amount = address(this).balance * percentage / 1e4;
        (bool success, ) = payable(_address).call{value: amount}("");
        require(success, "Withdraw amount failed");
    }

    receive() external payable {}
}
