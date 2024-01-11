//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
/*
                                      *****
                                     *******
                                    *********
                                   ***********
                                  *************
                                 ***************
                                 ***************
                                *****************
                               *******************
                              *********************
                             ********** ************
                            **********   *******  ***
                            *********     ****    ***
                           *   *****     ***      ****
                          **       **    **      ******
                         ***        *** **       *******
                        *****         ***        ********
                       ******          *          ********
                       ******         **          ********
                      *******         *           *********
                     ********        **           **********
                    ********        **             **********
                   *********        **             ***********
                   *********       **              ***********
                  **********       **              ************
                 ***********      **                ***** ******
                ************      **                *****  ******
               *************      **                ****    ******
              **************      *                 ****    *******
              **************     **                ****      ******
             ***************     **                ****       *****
            *****************    **                ***        ****
           ******************    *                ***         **     *
          ********************   *                **           *     **
         ********** ***********   *              *             *     ***
         **********  ***********  *             *              *********
        **********    *********** **           **          ****         *
       ***********    ***************        ***         ****
      ***********      ****************   ******      *****               *
     ************        **************   *****      ****                ***
    ******     **          ************   *****     ***                 *****
    ******     **           ***********   *****    ***                  *****
   *******     *              *********   ****    ***                  *******
  ********     *               ********   ****    **                   ********
 *******************           ********   ****   *                    *********
********         *****          *******   *****                       *********
******              *****       *******   ***** *                    **********
****                    **       ******   ******                     **********
*****                     **     ******   ******                    ***********
*******                     *    ******   *******                   ***********
########                     #   ######   #######                  ############
#########                     #  ######   ###### #                 ############
#########                        ######   #####                   #############
##########                       ######   #####   #              ##############
 ##########                     #######   ####    ####         ################
  #########                     #######   ####   ########    ##################
   #########                    #######   ####   #############################
    #########                   #######   ###    ############################
    #########                  ########   ###    ############################
     #########                  #######   ###   ############################
      #########                  ######   ##    ###########################
       #########           ##    ######   ##    ##########################
        ##########       #####    #####   ##    #########################
         ###########   #######    #####   #    #########################
         ######################   #####   #    #########################
          #####################    ####   #    ########################
           #####################   ####   #    #######################
            ####################   ####   #    ######################
             ###################   ####        #####################
              ##################   ####       #####################
              ##################    ###       #####################
               #################    ###       ####################
                #################   ###       ###################
                 ################   ###       ##################
                  ###############   ###       #################
                  ###############    ##      ##################
                   ##############    ##      #################
                    #############    ##      ################
                     ############    ##      ###############
                      ###########    ##      ##############
                       ##########    ##      #############
                       ##########    ##      #############
                        ##########   ##     #############
                         #########    #     ############
                          ########    #     ###########
                           #######    #     ##########
                            ######    #     #########
                            ######    #     #########
                             #####    #     ########
                              ####    #     #######
                               ###    #     ######
                                ##    #     #####
                                 #    #     ####
    The Dutch Dude               #    #     ####
    T.vanEck@fz.hse.nl                #     ###
                                      #     ##
                                      #     #
*/
import "Pausable.sol";
import "ECDSA.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";

contract Plant is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;

    address private payoutAddress;
    address public signerAddress;

    // // metadata URI
    string public notRevealedUri;
    string private _baseTokenURI;
    uint256 public revealTokenId = 0;

    uint256 public collectionSize;
    uint256 public maxBatchSize;
    uint256 public currentSaleIndex;

    enum SaleStage {
        Whitelist,
        Public
    }
    struct SaleConfig {
        uint32 startTime;
        uint32 endTime;
        uint64 price;
        SaleStage stage;
    }
    SaleConfig[] public saleConfigs;

    mapping(string => bool) public ticketUsed;

    constructor(address _signerAddress)
        ERC721A("Young Male Florist", "plant")
    {
        collectionSize = 3*6*5;
        maxBatchSize = 10;
        payoutAddress = 0x715331D8aCBFFFB017E7E95d109C6FCF9E1D470E;
        signerAddress = _signerAddress;
        currentSaleIndex = 0;

        SaleConfig memory whitelistSaleConfig = SaleConfig({
            startTime: 1651723200,
            endTime: 1651730400,
            price: 0.01 * 0.88 ether,
            stage: SaleStage.Whitelist
        });
        SaleConfig memory publicSaleConfig = SaleConfig({
            startTime: 1651732200,
            endTime: 1652543940,
            price: 0.01 ether,
            stage: SaleStage.Public
        });
        saleConfigs.push(whitelistSaleConfig);
        saleConfigs.push(publicSaleConfig);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier checkMintConstraint(uint256 quantity) {
        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 price = uint256(config.price);

        require(quantity <= maxBatchSize, "Exceed mint quantity limit.");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(msg.value >= price * quantity, "Need to send more ETH.");
        _;
    }

    function whitelistMint(
        uint256 quantity,
        string memory _ticket,
        bytes memory _signature
    ) external payable callerIsUser checkMintConstraint(quantity) {
        proceedSaleStageIfNeed();

        require(isSaleStageOn(SaleStage.Whitelist), "sale has not started yet");

        require(!ticketUsed[_ticket], "Ticket has already been used");
        require(
            isAuthorized(msg.sender, _ticket, _signature, signerAddress),
            "Ticket is invalid"
        );

        ticketUsed[_ticket] = true;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        checkMintConstraint(quantity)
    {
        proceedSaleStageIfNeed();
        require(isSaleStageOn(SaleStage.Public), "sale has not started yet");

        _safeMint(msg.sender, quantity);
    }

    function proceedSaleStageIfNeed() private {
        while (saleConfigs.length > currentSaleIndex + 1) {
            SaleConfig memory config = saleConfigs[currentSaleIndex];
            uint256 nextStageSaleEndTime = uint256(config.endTime);

            if (block.timestamp >= nextStageSaleEndTime) {
                currentSaleIndex += 1;
            } else {
                return;
            }
        }
    }

    function checkEnoughPrice(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
    }

    function isSaleStageOn(SaleStage _stage) private view returns (bool) {
        if (saleConfigs.length <= currentSaleIndex) {
            return false;
        }

        SaleConfig memory config = saleConfigs[currentSaleIndex];
        uint256 stagePrice = uint256(config.price);
        uint256 stageSaleStartTime = uint256(config.startTime);
        SaleStage currentStage = config.stage;

        return
            stagePrice != 0 &&
            currentStage == _stage &&
            block.timestamp >= stageSaleStartTime;
    }

    function setSaleConfig(
        uint256 _saleIndex,
        uint32 _startTime,
        uint32 _endTime,
        uint64 _price,
        SaleStage _stage
    ) external onlyOwner {
        SaleConfig memory config = SaleConfig({
            startTime: _startTime,
            endTime: _endTime,
            price: _price,
            stage: _stage
        });

        if (_saleIndex >= saleConfigs.length) {
            saleConfigs.push(config);
        } else {
            saleConfigs[_saleIndex] = config;
        }
    }

    function setCurrentSaleIndex(uint256 _currentSaleIndex) external onlyOwner {
        currentSaleIndex = _currentSaleIndex;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (tokenId >= revealTokenId) {
            return notRevealedUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setRevealTokenId(uint256 _revealTokenId) external onlyOwner {
        revealTokenId = _revealTokenId;
    }

    function setNotRevealedUri(string calldata _notRevealedUri)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedUri;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(payoutAddress).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function mintForAirdrop(address _to, uint256 _mintAmount)
        external
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= collectionSize, "Exceed max supply");

        _safeMint(_to, _mintAmount);
    }

    function mintForAirdrop(address[] memory _to, uint256 _mintAmount)
        external
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            supply + _to.length * _mintAmount <= collectionSize,
            "Exceed max supply"
        );

        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _mintAmount);
        }
    }

    function setMaxBatchSize(uint256 _newMaxBatchSize) external onlyOwner {
        maxBatchSize = _newMaxBatchSize;
    }

    function setCollectionSize(uint256 _newCollectionSize) external onlyOwner {
        collectionSize = _newCollectionSize;
    }

    function isTicketAvailable(string memory ticket, bytes memory signature)
        external
        view
        returns (bool)
    {
        return
            !ticketUsed[ticket] &&
            isAuthorized(msg.sender, ticket, signature, signerAddress);
    }

    function isAuthorized(
        address sender,
        string memory ticket,
        bytes memory signature,
        address _signerAddress
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, ticket));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return _signerAddress == signedHash.recover(signature);
    }
}