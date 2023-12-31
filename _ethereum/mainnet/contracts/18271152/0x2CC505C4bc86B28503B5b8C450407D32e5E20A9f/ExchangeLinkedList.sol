// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

library ExchangeLinkedList {
    error NoMatchPrice(uint256 askHead, uint256 bidHead, uint256 lmp);

    struct PriceLinkedList {
        /// Hashmap-style linked list of prices to route orders
        // key: price, value: next_price (next_price > price)
        mapping(uint256 => uint256) askPrices;
        // key: price, value: next_price (next_price < price)
        mapping(uint256 => uint256) bidPrices;
        // Head of the bid price linked list(i.e. highest bid price)
        uint256 askHead;
        // Head of the ask price linked list(i.e. lowest ask price)
        uint256 bidHead;
        // Last matched price
        uint256 lmp;
    }

    function _setLmp(PriceLinkedList storage self, uint256 lmp_) internal {
        self.lmp = lmp_;
    }

    function _heads(
        PriceLinkedList storage self
    ) internal view returns (uint256, uint256) {
        return (self.bidHead, self.askHead);
    }

    function _askHead(
        PriceLinkedList storage self
    ) internal view returns (uint256) {
        return self.askHead;
    }

    function _bidHead(
        PriceLinkedList storage self
    ) internal view returns (uint256) {
        return self.bidHead;
    }

    function _mktPrice(
        PriceLinkedList storage self
    ) internal view returns (uint256) {
        if (self.lmp == 0) {
            if (self.bidHead == 0 && self.askHead == 0) {
                revert NoMatchPrice(self.bidHead, self.askHead, self.lmp);
            } else if (self.bidHead != 0 && self.askHead != 0) {
                return (self.bidHead + self.askHead) / 2;
            } else {
                return self.askHead == 0 ? self.bidHead : self.askHead;
            }
        } else {
            if (self.lmp < self.bidHead) {
                return self.bidHead;
            } else if (self.lmp > self.askHead && self.askHead != 0) {
                return self.askHead;
            } else {
                return self.lmp;
            }
        }
    }

    function _next(
        PriceLinkedList storage self,
        bool isBid,
        uint256 price
    ) internal view returns (uint256) {
        if (isBid) {
            return self.bidPrices[price];
        } else {
            return self.askPrices[price];
        }
    }

    // for bidPrices, lower ones are next, for askPrices, higher ones are next
    function _insert(
        PriceLinkedList storage self,
        bool isBid,
        uint256 price
    ) internal {
        if (isBid) {
            uint256 last = 0;
            uint256 head = self.bidHead;
            // insert bid price to the linked list
            // if the list is empty
            if (head == 0 || price > head) {
                self.bidHead = price;
                self.bidPrices[price] = head;
                return;
            }
            while (head != 0) {
                uint256 next = self.bidPrices[head];
                if (price < next) {
                    // Keep traversing
                    head = self.bidPrices[head];
                    last = next;
                } else if (price > next) {
                    if (next == 0) {
                        // Insert price at the end of the list
                        self.bidPrices[head] = price;
                        self.bidPrices[price] = 0;
                        return;
                    }
                    // Insert price in the middle of the list
                    self.bidPrices[head] = price;
                    self.bidPrices[price] = next;
                    return;
                } else {
                    // price is already included in the queue as it is equal to next
                    // End traversal as there is no need to traverse further
                    return;
                }
            }
        }
        // insert ask price to the linked list
        else {
            uint256 last = 0;
            uint256 head = self.askHead;
            // insert order to the linked list
            // if the list is empty and price is the lowest ask
            if (head == 0 || price < head) {
                self.askHead = price;
                self.askPrices[price] = head;
                return;
            }
            // traverse the list
            while (head != 0) {
                uint256 next = self.askPrices[head];
                // Keep traversing
                if (price > next) {
                    if (next == 0) {
                        // Insert price in the middle of the list
                        self.askPrices[head] = price;
                        self.askPrices[price] = 0;
                        return;
                    }
                    head = self.askPrices[head];
                    last = next;
                } else if (price < next) {
                    // Insert price in the middle of the list
                    self.askPrices[head] = price;
                    self.askPrices[price] = next;
                    return;
                } else {
                    // price is already included in the queue as it is equal to next
                    // End traversal as there is no need to traverse further
                    return;
                }
            }
        }
    }

    // show n prices shown in the orderbook
    function _getPrices(
        PriceLinkedList storage self,
        bool isBid,
        uint256 n
    ) internal view returns (uint256[] memory) {
        uint256 i = 0;
        uint256[] memory prices = new uint256[](n);
        for (
            uint256 price = isBid ? self.bidHead : self.askHead;
            price != 0 && i < n;
            price = isBid ? self.bidPrices[price] : self.askPrices[price]
        ) {
            prices[i] = price;
            i++;
        }
        return prices;
    }
}
