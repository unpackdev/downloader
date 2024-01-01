pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC721.sol";

import "./IERC721Receiver.sol";

import "./IERC20.sol";

import "./AbstractNFT.sol";

// This contract inherits all functionality from AbstractNFT and implements arbitrary price for pixels.

contract PriceFeeValueTrackNFT is AbstractNFT {
    uint16 internal priceFeeBasisPoints;

    mapping(address => uint256) private userValues;

    constructor(
        string memory __name,
        address _token,
        address _dev,
        uint256 _mintFee,
        uint16 _priceFeeBasisPoints,
        uint16 _acquisitionTaxBasisPoints
    )
        public
        AbstractNFT(__name, _token, _dev, _mintFee, _acquisitionTaxBasisPoints)
    {
        priceFeeBasisPoints = _priceFeeBasisPoints;
    }

    function getPriceFeeBasisPoints() public view returns (uint16) {
        return priceFeeBasisPoints;
    }

    function changePriceFeeBasisPoints(uint16 _newbp) public onlyOwner {
        priceFeeBasisPoints = _newbp;
    }

    function valueOf(address user) public view returns (uint256) {
        return userValues[user];
    }

    function unsafeTransferPixel(uint256 tokenId, address to) public override {
        require(_ownerOf(tokenId) == msg.sender);

        // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

        // transfer
        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

         // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {

        // Change original owners value
        userValues[_ownerOf(tokenId)] -= prices[tokenId];

        // Change users value
        userValues[to] += prices[tokenId];

        _transfer(from, to, tokenId);
        require(__checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function __checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * Minting functions
     */
    function mintPixel(uint256 id, uint24 c) public pure override {
        revert();
    }

    function mintPixelBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public pure override {
        revert();
    }

    /*
     * Full committers
     */
    function commit(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice
    ) public override {
        uint256 totalFee = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == msg.sender) {
                pixelColor[tokenId] = c;

                // Change users value bases on price difference
                // Change can be negative
                if (newPrice > prices[tokenId]) {
                    userValues[msg.sender] += newPrice - prices[tokenId];

                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                } else {
                    userValues[msg.sender] -= prices[tokenId] - newPrice;
                }

                prices[tokenId] = newPrice;
            } else {
                // Change original owners value
                userValues[_ownerOf(tokenId)] -= prices[tokenId];

                // Change users value
                userValues[msg.sender] += newPrice;

                if (newPrice > prices[tokenId]) {
                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                // Pay pixel owner BEFORE CALLING _transfer !!!!
                IERC20(token).transferFrom(
                    msg.sender,
                    _ownerOf(tokenId),
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                        10000
                );

                // Acquire token
                _transfer(_ownerOf(tokenId), msg.sender, tokenId);

                // Transaction tax
                totalFee +=
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                // Set color
                pixelColor[tokenId] = c;

                // Set new price
                prices[tokenId] = newPrice;
            }
        } else {
            _mint(msg.sender, tokenId);

            idmap[idcount] = tokenId;
            idcount = idcount + 1;

            // Set color
            pixelColor[tokenId] = c;

            // Increase users value
            userValues[msg.sender] += newPrice;

            // Apply price based fee (price[tokenId] = 0)
            totalFee += mintFee + (newPrice * priceFeeBasisPoints) / 10000;

            // Set new price
            prices[tokenId] = newPrice;
        }

        IERC20(token).transferFrom(msg.sender, dev, totalFee);
    }

    /*
     * Full committers
     */
    function commitBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices
    ) public override {
        uint256 totalFee = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == msg.sender) {
                    pixelColor[tokenIds[i]] = cs[i];

                    // Change users value bases on price difference
                    // Change can be negative
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        userValues[msg.sender] +=
                            newPrices[i] -
                            prices[tokenIds[i]];

                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    } else {
                        userValues[msg.sender] -=
                            prices[tokenIds[i]] -
                            newPrices[i];
                    }

                    prices[tokenIds[i]] = newPrices[i];
                } else {
                    // Change original owners value
                    userValues[_ownerOf(tokenIds[i])] -= prices[tokenIds[i]];

                    // Change users value
                    userValues[msg.sender] += newPrices[i];

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    // Pay pixel owner BEFORE CALLING _transfer !!!!!!
                    IERC20(token).transferFrom(
                        msg.sender,
                        _ownerOf(tokenIds[i]),
                        (prices[tokenIds[i]] *
                            (10000 - acquisitionTaxBasisPoints)) / 10000
                    );

                    // Acquire token
                    _transfer(_ownerOf(tokenIds[i]), msg.sender, tokenIds[i]);

                    // Transaction fee
                    totalFee +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    // repaint
                    pixelColor[tokenIds[i]] = cs[i];

                    // Set new price
                    prices[tokenIds[i]] = newPrices[i];
                }
            } else {
                _mint(msg.sender, tokenIds[i]);

                idmap[idcount] = tokenIds[i];
                idcount = idcount + 1;

                pixelColor[tokenIds[i]] = cs[i];

                // Apply price based fee (prices[tokenIds[i]] = 0)
                totalFee +=
                    mintFee +
                    (newPrices[i] * priceFeeBasisPoints) /
                    10000;

                // Change users value
                userValues[msg.sender] += newPrices[i];

                // Set new price
                prices[tokenIds[i]] = newPrices[i];
            }
        }

        IERC20(token).transferFrom(msg.sender, dev, totalFee);
    }

    function getCommitFeeTaxPriceAndCounts(
        uint256 tokenId,
        uint256 newPrice,
        address beneficiary
    ) public view override returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.

        uint256[3] memory _feeTaxPrice;
        _feeTaxPrice[0] = 0;
        _feeTaxPrice[1] = 0;
        _feeTaxPrice[2] = 0;

        uint16[2] memory _mcoc;
        _mcoc[0] = 0;
        _mcoc[1] = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == beneficiary) {
                // nothing

                if (newPrice > prices[tokenId]) {
                    _feeTaxPrice[0] +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }
            } else {
                _feeTaxPrice[2] =
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                    10000;

                if (newPrice > prices[tokenId]) {
                    _feeTaxPrice[0] +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                _feeTaxPrice[1] =
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                _mcoc[1]++;
            }
        } else {
            _feeTaxPrice[0] +=
                mintFee +
                (newPrice * priceFeeBasisPoints) /
                10000;
            _mcoc[0]++;
        }

        return (_feeTaxPrice, _mcoc);
    }

    function getCommitBulkFeeTaxPriceAndCounts(
        uint256[] calldata tokenIds,
        uint256[] calldata newPrices,
        address beneficiary
    ) public view override returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.

        uint256[3] memory _feeTaxPrice;
        _feeTaxPrice[0] = 0;
        _feeTaxPrice[1] = 0;
        _feeTaxPrice[2] = 0;

        uint16[2] memory _mcoc;
        _mcoc[0] = 0;
        _mcoc[1] = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == beneficiary) {
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        _feeTaxPrice[0] +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }
                } else {
                    _feeTaxPrice[2] +=
                        (prices[tokenIds[i]] *
                            (10000 - acquisitionTaxBasisPoints)) /
                        10000;

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        _feeTaxPrice[0] +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    _feeTaxPrice[1] +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    _mcoc[1]++;
                }
            } else {
                _feeTaxPrice[0] +=
                    mintFee +
                    (newPrices[i] * priceFeeBasisPoints) /
                    10000;
                _mcoc[0]++;
            }
        }

        return (_feeTaxPrice, _mcoc);
    }

    /*
     * Full committers
     */
    function commitForBeneficiary(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice,
        address beneficiary
    ) public override {
        uint256 totalFee = 0;

        if (_exists(tokenId)) {
            if (_ownerOf(tokenId) == beneficiary) {
                pixelColor[tokenId] = c;

                // Change users value bases on price difference
                // Change can be negative
                if (newPrice > prices[tokenId]) {
                    userValues[beneficiary] += newPrice - prices[tokenId];

                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                } else {
                    userValues[beneficiary] -= prices[tokenId] - newPrice;
                }

                prices[tokenId] = newPrice;
            } else {
                // Change original owners value
                userValues[_ownerOf(tokenId)] -= prices[tokenId];

                // Change users value
                userValues[beneficiary] += newPrice;

                if (newPrice > prices[tokenId]) {
                    // Apply price based fee
                    totalFee +=
                        ((newPrice - prices[tokenId]) * priceFeeBasisPoints) /
                        10000;
                }

                // Acquire token
                _transfer(_ownerOf(tokenId), beneficiary, tokenId);

                // Pay pixel owner
                IERC20(token).transferFrom(
                    beneficiary,
                    _ownerOf(tokenId),
                    (prices[tokenId] * (10000 - acquisitionTaxBasisPoints)) /
                        10000
                );

                // Transaction tax
                totalFee +=
                    (prices[tokenId] * (acquisitionTaxBasisPoints)) /
                    10000;

                // Set color
                pixelColor[tokenId] = c;

                // Set new price
                prices[tokenId] = newPrice;
            }
        } else {
            _mint(beneficiary, tokenId);

            idmap[idcount] = tokenId;
            idcount = idcount + 1;

            // Set color
            pixelColor[tokenId] = c;

            // Increase users value
            userValues[beneficiary] += newPrice;

            // Apply price based fee (price[tokenId] = 0)
            totalFee += (newPrice * priceFeeBasisPoints) / 10000;

            // Set new price
            prices[tokenId] = newPrice;
        }

        IERC20(token).transferFrom(beneficiary, dev, totalFee);
    }

    /*
     * Full committers
     */
    /*
     *  Does not compile; stack too deep
     */
    function commitBulkForBeneficiary(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices,
        address beneficiary
    ) public override {
        // uint256 totalFee = 0;

        // // WARN: This unbounded for loop is an anti-pattern
        // for (uint i = 0; i < tokenIds.length; i++) {
        //     if (_exists(tokenIds[i])) {
        //         if (_ownerOf(tokenIds[i]) == msg.sender) {
        //             pixelColor[tokenIds[i]] = cs[i];

        //             // Apply price based fee
        //             if (newPrices[i] > prices[tokenIds[i]]) {
        //                 totalFee +=
        //                     ((newPrices[i] - prices[tokenIds[i]]) *
        //                         priceFeeBasisPoints) /
        //                     10000;
        //             }

        //             prices[tokenIds[i]] = newPrices[i];
        //         } else {
        //             // Acquire token
        //             _transfer(_ownerOf(tokenIds[i]), msg.sender, tokenIds[i]);

        //             // Pay pixel owner
        //             // New variable is needed to avoid 'stack too deep' error.
        //             uint256 transferprice = (prices[tokenIds[i]] *
        //                 (10000 - acquisitionTaxBasisPoints)) / 10000;

        //             IERC20(token).transferFrom(
        //                 beneficiary,
        //                 _ownerOf(tokenIds[i]),
        //                 transferprice
        //             );

        //             // Transaction fee
        //             totalFee +=
        //                 (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
        //                 10000;

        //             // repaint
        //             pixelColor[tokenIds[i]] = cs[i];

        //             // Apply price based fee
        //             if (newPrices[i] > prices[tokenIds[i]]) {
        //                 totalFee +=
        //                     ((newPrices[i] - prices[tokenIds[i]]) *
        //                         priceFeeBasisPoints) /
        //                     10000;
        //             }

        //             // Set new price
        //             prices[tokenIds[i]] = newPrices[i];
        //         }
        //     } else {
        //         _mint(msg.sender, tokenIds[i]);

        //         idmap[idcount] = tokenIds[i];
        //         idcount = idcount + 1;

        //         pixelColor[tokenIds[i]] = cs[i];

        //         // Apply price based fee (prices[tokenIds[i]] = 0)
        //         totalFee += (newPrices[i] * priceFeeBasisPoints) / 10000;

        //         // Set new price
        //         prices[tokenIds[i]] = newPrices[i];
        //     }
        // }

        // IERC20(token).transferFrom(msg.sender, dev, totalFee);
        uint256 totalFee = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                if (_ownerOf(tokenIds[i]) == beneficiary) {
                    pixelColor[tokenIds[i]] = cs[i];

                    // Change users value bases on price difference
                    // Change can be negative
                    if (newPrices[i] > prices[tokenIds[i]]) {
                        userValues[beneficiary] +=
                            newPrices[i] -
                            prices[tokenIds[i]];

                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    } else {
                        userValues[beneficiary] -=
                            prices[tokenIds[i]] -
                            newPrices[i];
                    }

                    prices[tokenIds[i]] = newPrices[i];
                } else {
                    // Change original owners value
                    userValues[_ownerOf(tokenIds[i])] -= prices[tokenIds[i]];

                    // Change users value
                    userValues[beneficiary] += newPrices[i];

                    if (newPrices[i] > prices[tokenIds[i]]) {
                        // Apply price based fee
                        totalFee +=
                            ((newPrices[i] - prices[tokenIds[i]]) *
                                priceFeeBasisPoints) /
                            10000;
                    }

                    // Acquire token
                    _transfer(_ownerOf(tokenIds[i]), beneficiary, tokenIds[i]);

                    // Pay pixel owner
                    // New variable is needed to avoid 'stack too deep' error.
                    uint256 transferprice = (prices[tokenIds[i]] *
                        (10000 - acquisitionTaxBasisPoints)) / 10000;

                    IERC20(token).transferFrom(
                        beneficiary,
                        _ownerOf(tokenIds[i]),
                        transferprice
                    );

                    // Transaction fee
                    totalFee +=
                        (prices[tokenIds[i]] * (acquisitionTaxBasisPoints)) /
                        10000;

                    // repaint
                    pixelColor[tokenIds[i]] = cs[i];

                    // Set new price
                    prices[tokenIds[i]] = newPrices[i];
                }
            } else {
                _mint(beneficiary, tokenIds[i]);

                idmap[idcount] = tokenIds[i];
                idcount = idcount + 1;

                pixelColor[tokenIds[i]] = cs[i];

                // Apply price based fee (prices[tokenIds[i]] = 0)
                totalFee += (newPrices[i] * priceFeeBasisPoints) / 10000;

                // Change users value
                userValues[beneficiary] += newPrices[i];

                // Set new price
                prices[tokenIds[i]] = newPrices[i];
            }
        }

        IERC20(token).transferFrom(beneficiary, dev, totalFee);
    }
}
