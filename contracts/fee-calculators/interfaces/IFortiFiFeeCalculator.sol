// SPDX-License-Identifier: MIT
// IFortiFiFeeCalculator Interface by FortiFi

pragma solidity ^0.8.2;

interface IFortiFiFeeCalculator {
    function getFees(address _user, uint256 _amount) external view returns(uint256);
}