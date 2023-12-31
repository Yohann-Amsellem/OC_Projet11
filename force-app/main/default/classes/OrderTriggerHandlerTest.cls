@isTest
public class OrderTriggerHandlerTest {
  @isTest
  public static void testHandleBeforeUpdate() {
    // Create test data
    List<Order> testOrders = new List<Order>();

    TestDataFactoryP11.makeOrders(5, 3, 'Activated');

    // Update the orders to transition from Draft to Active status
    for (Order order : testOrders) {
      order.Status = 'Active';
    }

    Test.startTest();

    // Call the trigger handler method
    OrderTriggerHandler.handleBeforeUpdate(testOrders);

    Test.stopTest();

    // Verify the results
    for (Order order : testOrders) {
      if (
        order.Status == 'Active' && !OrderTriggerHandler.hasProducts(order.Id)
      ) {
        System.assert(
          OrderTriggerHandler.hasErrors(order),
          'Error message should be added to the order'
        );
      }
    }
  }

  @isTest
  public static void testHandleAfterDelete() {
    // Generate test data
    Integer numAccounts = 2;
    Integer numOrdersPerAccount = 3;
    String orderStatus = 'Draft';

    // Generate Orders and Accounts using TestDataFactoryP11
    List<Order> testOrders = TestDataFactoryP11.makeOrders(
      numAccounts,
      numOrdersPerAccount,
      orderStatus
    );
    List<Account> updatedAccounts = [
      SELECT Active__c
      FROM Account
      WHERE Id IN (SELECT AccountId FROM Order)
    ];
    // Account acc = new account();
    for (Account acc : updatedAccounts) {
      acc.Active__c = true;
    }
    Test.startTest();

    // Delete the orders
    delete [SELECT Id FROM Order LIMIT 2];

    Test.stopTest();

    // Verify the results

    System.assertEquals(
      true,
      updatedAccounts[1].Active__c,
      'Active__c field should be true after order deletion if there are still orders left'
    );
  }

  @isTest
  public static void testHandleAfterDelete_NoOrders() {
    // Generate test data
    Integer numAccounts = 2;
    Integer numOrdersPerAccount = 3;
    String orderStatus = 'Draft';

    // Generate Accounts without Orders using TestDataFactoryP11
    TestDataFactoryP11.makeOrders(
      numAccounts,
      numOrdersPerAccount,
      orderStatus
    );

    // Delete all Orders
    delete [SELECT Id FROM Order];

    Test.startTest();

    // Trigger the handleAfterDelete logic
    OrderTriggerHandler.handleAfterDelete(new List<Order>());

    Test.stopTest();

    // Verify the results
    List<Account> updatedAccounts = [SELECT Active__c FROM Account];
    for (Account account : updatedAccounts) {
      System.assertEquals(
        false,
        account.Active__c,
        'Active__c field should be false when no orders exist'
      );
    }
  }
}
