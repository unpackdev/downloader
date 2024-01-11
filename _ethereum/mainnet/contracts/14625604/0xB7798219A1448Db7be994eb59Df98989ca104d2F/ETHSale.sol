// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BBBBBBBGG&@@@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P!:          :P@@@@&P7^.        .^?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&J.            :#@@@#7.                  :Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&!              Y@@@B:                        !&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@P               B@@@~                            J@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@J               B@@&.                              ~@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@G               7@@@.                                7@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@Y                                  #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               .@@@&##########&&&&&&&&&&&#############@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               .@@@@@@@@@@@@@@#B######&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@@@@@@@@@@@@B~         .:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@B               !@@@@@@@@@@@@@@@&!            .7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@Y               G@@@@@@@@@@@@@@@@B.             ^#@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@G               B@@@@@@@@@@@@@@@@@:              7@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@?              J@@@@@@@@@@@@@@@@@.              ^@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@5:            .B@@@@@@@@@@@@@@@B               ~@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^.         :P@@@@@@@@@@@@@@:               #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#######BB&@@@@@@@@@@@@@7               J@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?               J@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.                                 ^@@@:               B@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@Y                                 G@@#               ^@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@!                               Y@@@:              .@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@Y                             P@@@^              ~@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&~                         !&@@&.             :B@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&?.                   .J&@@@?             !B@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y~.           :!5&@@@#7          .^JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGGB#&@@@@@@@@BPGGGGGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./Math.sol";
import "./SaleCommon.sol";

contract ETHSale is AccessControl, SaleCommon {
    struct Sale {
        uint256 id;
        uint256 volume;
        uint256 presale;
        uint256 starttime; // to start immediately, set starttime = 0
        uint256 endtime;
        bool active;
        bytes32 merkleRoot; // Merkle root of the entrylist Merkle tree, 0x00 for non-merkle sale
        uint256 maxQuantity;
        uint256 price; // in Wei, where 10^18 Wei = 1 ETH
        uint256 startTokenIndex;
        uint256 maxPLOTs;
        uint256 mintedPLOTs;
    }

    Sale[] public sales;
    mapping(uint256 => mapping(address => uint256)) public minted; // sale ID => account => quantity

    /// @notice Constructor
    /// @param _plot Storyverse Plot contract
    constructor(address _plot) SaleCommon(_plot) {}

    /// @notice Get the current sale
    /// @return Current sale
    function currentSale() public view returns (Sale memory) {
        require(sales.length > 0, "no current sale");
        return sales[sales.length - 1];
    }

    /// @notice Get the current sale ID
    /// @return Current sale ID
    function currentSaleId() public view returns (uint256) {
        require(sales.length > 0, "no current sale");
        return sales.length - 1;
    }

    /// @notice Checks if the provided token ID parameters are likely to overlap a previous or current sale
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    /// @return valid_ If the current token ID range paramters are likely safe
    function isSafeTokenIdRange(uint256 _startTokenIndex, uint256 _maxPLOTs)
        external
        view
        returns (bool valid_)
    {
        return _isSafeTokenIdRange(_startTokenIndex, _maxPLOTs, sales.length);
    }

    function _checkSafeTokenIdRange(
        uint256 _startTokenIndex,
        uint256 _maxPLOTs,
        uint256 _maxSaleId
    ) internal view {
        // If _maxSaleId is passed in as the current sale ID, then
        // the check will skip the current sale ID in _isSafeTokenIdRange()
        // since in that case _maxSaleId == sales.length - 1
        require(
            _isSafeTokenIdRange(_startTokenIndex, _maxPLOTs, _maxSaleId),
            "overlapping token ID range"
        );
    }

    function _isSafeTokenIdRange(
        uint256 _startTokenIndex,
        uint256 _maxPLOTs,
        uint256 _maxSaleId
    ) internal view returns (bool valid_) {
        if (_maxPLOTs == 0) {
            return true;
        }

        for (uint256 i = 0; i < _maxSaleId; i++) {
            // if no minted PLOTs in sale, ignore
            if (sales[i].mintedPLOTs == 0) {
                continue;
            }

            uint256 saleStartTokenIndex = sales[i].startTokenIndex;
            uint256 saleMintedPLOTs = sales[i].mintedPLOTs;

            if (_startTokenIndex < saleStartTokenIndex) {
                // start index is less than the sale's start token index, so ensure
                // it doesn't extend into the sale's range if max PLOTs are minted
                if (_startTokenIndex + _maxPLOTs - 1 >= saleStartTokenIndex) {
                    return false;
                }
            } else {
                // start index greater than or equal to the sale's start token index, so ensure
                // it starts after the sale's start token index + the number of PLOTs minted
                if (_startTokenIndex <= saleStartTokenIndex + saleMintedPLOTs - 1) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @notice Adds a new sale
    /// @param _volume Volume of the sale
    /// @param _presale Presale of the sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    /// @param _price Price of each PLOT
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function addSale(
        uint256 _volume,
        uint256 _presale,
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _startTokenIndex,
        uint256 _maxPLOTs
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = sales.length;

        checkTokenParameters(_volume, _presale, _startTokenIndex);

        _checkSafeTokenIdRange(_startTokenIndex, _maxPLOTs, saleId);

        Sale memory sale = Sale({
            id: saleId,
            volume: _volume,
            presale: _presale,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            startTokenIndex: _startTokenIndex,
            maxPLOTs: _maxPLOTs,
            mintedPLOTs: 0
        });

        sales.push(sale);

        emit SaleAdded(msg.sender, saleId);
    }

    /// @notice Updates the current sale
    /// @param _volume Volume of the sale
    /// @param _presale Presale of the sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    /// @param _price Price of each PLOT
    /// @param _startTokenIndex Token index to start the sale from
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function updateSale(
        uint256 _volume,
        uint256 _presale,
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _startTokenIndex,
        uint256 _maxPLOTs
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(_volume, _presale, _startTokenIndex);
        _checkSafeTokenIdRange(_startTokenIndex, _maxPLOTs, saleId);

        Sale memory sale = Sale({
            id: saleId,
            volume: _volume,
            presale: _presale,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            startTokenIndex: _startTokenIndex,
            maxPLOTs: _maxPLOTs,
            mintedPLOTs: sales[saleId].mintedPLOTs
        });

        sales[saleId] = sale;

        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the volume of the current sale
    /// @param _volume Volume of the sale
    function updateSaleVolume(uint256 _volume) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(_volume, sales[saleId].presale, sales[saleId].startTokenIndex);

        sales[saleId].volume = _volume;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the presale of the current sale
    /// @param _presale Presale of the sale
    function updateSalePresale(uint256 _presale) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        checkTokenParameters(sales[saleId].volume, _presale, sales[saleId].startTokenIndex);

        sales[saleId].presale = _presale;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the start time of the current sale
    /// @param _starttime Start time of the sale
    function updateSaleStarttime(uint256 _starttime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].starttime = _starttime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the end time of the current sale
    /// @param _endtime End time of the sale
    function updateSaleEndtime(uint256 _endtime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].endtime = _endtime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the active status of the current sale
    /// @param _active Whether the sale is active
    function updateSaleActive(bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].active = _active;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the merkle root of the current sale
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    function updateSaleMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].merkleRoot = _merkleRoot;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the max quantity of the current sale
    /// @param _maxQuantity Maximum number of PLOTs per account that can be sold
    function updateSaleMaxQuantity(uint256 _maxQuantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].maxQuantity = _maxQuantity;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the price of each PLOT for the current sale
    /// @param _price Price of each PLOT
    function updateSalePrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].price = _price;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the start token index of the current sale
    /// @param _startTokenIndex Token index to start the sale from
    function updateSaleStartTokenIndex(uint256 _startTokenIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 saleId = currentSaleId();

        _checkSafeTokenIdRange(_startTokenIndex, sales[saleId].maxPLOTs, saleId);
        checkTokenParameters(sales[saleId].volume, sales[saleId].presale, _startTokenIndex);

        sales[saleId].startTokenIndex = _startTokenIndex;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the  of the current sale
    /// @param _maxPLOTs Maximum number of PLOTs that can be minted in this sale
    function updateSaleMaxPLOTs(uint256 _maxPLOTs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        _checkSafeTokenIdRange(sales[saleId].startTokenIndex, _maxPLOTs, saleId);

        sales[saleId].maxPLOTs = _maxPLOTs;
        emit SaleUpdated(msg.sender, saleId);
    }

    function _mintTo(
        address _to,
        uint256 _volume,
        uint256 _presale,
        uint256 _startTokenIndex,
        uint256 _quantity
    ) internal {
        require(_quantity > 0, "quantity must be greater than 0");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenIndex = _startTokenIndex + i;
            uint256 tokenId = buildTokenId(_volume, _presale, tokenIndex);

            IStoryversePlot(plot).safeMint(_to, tokenId);
        }

        emit Minted(msg.sender, _to, _quantity, msg.value);
    }

    /// @notice Mints new tokens in exchange for ETH
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function mintTo(address _to, uint256 _quantity) external payable nonReentrant {
        Sale memory sale = currentSale();

        // only proceed if no merkle root is set
        require(sale.merkleRoot == bytes32(0), "merkle sale requires valid proof");

        // check sale validity
        require(sale.active, "sale is inactive");
        require(block.timestamp >= sale.starttime, "sale has not started");
        require(block.timestamp < sale.endtime, "sale has ended");

        // validate payment and authorized quantity
        require(msg.value == sale.price * _quantity, "incorrect payment for quantity and price");
        require(
            minted[sale.id][msg.sender] + _quantity <= sale.maxQuantity,
            "exceeds allowed quantity"
        );

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Mints new tokens in exchange for ETH based on the sale's entry list
    /// @param _proof Merkle proof to validate the caller is on the sale's entry list
    /// @param _maxQuantity Max quantity that the caller can mint
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function entryListMintTo(
        bytes32[] calldata _proof,
        uint256 _maxQuantity,
        address _to,
        uint256 _quantity
    ) external payable nonReentrant {
        Sale memory sale = currentSale();

        // validate merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxQuantity));
        require(MerkleProof.verify(_proof, sale.merkleRoot, leaf), "invalid proof");

        // check sale validity
        require(sale.active, "sale is inactive");
        require(block.timestamp >= sale.starttime, "sale has not started");
        require(block.timestamp < sale.endtime, "sale has ended");

        // validate payment and authorized quantity
        require(msg.value == sale.price * _quantity, "incorrect payment for quantity and price");
        require(
            minted[sale.id][msg.sender] + _quantity <= Math.max(sale.maxQuantity, _maxQuantity),
            "exceeds allowed quantity"
        );

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Administrative mint function within the constraints of the current sale, skipping some checks
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminSaleMintTo(address _to, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        Sale memory sale = currentSale();

        // check sale supply
        require(sale.mintedPLOTs + _quantity <= sale.maxPLOTs, "insufficient supply");

        sales[sale.id].mintedPLOTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(
            _to,
            sale.volume,
            sale.presale,
            sale.startTokenIndex + sale.mintedPLOTs,
            _quantity
        );
    }

    /// @notice Administrative mint function
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminMintTo(
        address _to,
        uint256 _volume,
        uint256 _presale,
        uint256 _startTokenIndex,
        uint256 _quantity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // add a sale (clobbering any current sale) to ensure token ranges
        // are respected and recorded
        addSale(
            _volume,
            _presale,
            block.timestamp,
            block.timestamp,
            false,
            bytes32(0),
            0,
            2**256 - 1,
            _startTokenIndex,
            _quantity
        );

        // record the sale as fully minted
        sales[sales.length - 1].mintedPLOTs = _quantity;

        _mintTo(_to, _volume, _presale, _startTokenIndex, _quantity);
    }
}
