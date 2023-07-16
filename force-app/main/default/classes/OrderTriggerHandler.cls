public class OrderTriggerHandler {
  public static void handleBeforeUpdate(List<Order> updatedOrders) {
    List<Order> ordersToValidate = new List<Order>();

    for (Order updatedOrder : updatedOrders) {
      if (updatedOrder.Status == 'Activated') {
        Order oldOrder = [
          SELECT Id, Status
          FROM Order
          WHERE Id = :updatedOrder.Id
        ];
        if (oldOrder.Status != 'Activated') {
          ordersToValidate.add(updatedOrder);
        }
      }
    }

    if (!ordersToValidate.isEmpty()) {
      validateOrders(ordersToValidate);
    }
  }

  private static void validateOrders(List<Order> orders) {
    for (Order order : orders) {
      if (!hasProducts(order.Id)) {
        order.addError(
          'Veuillez saisir des produits avant d\'activer la commande.'
        );
      }
    }
  }

  public static Boolean hasProducts(Id orderId) {
    // Implementation to check if the order has products
    // You can customize this logic based on your data model

    // Example implementation:
    List<OrderItem> orderItems = [
      SELECT Id
      FROM OrderItem
      WHERE OrderId = :orderId
      LIMIT 1
    ];
    return !orderItems.isEmpty();
  }

  public static Boolean hasErrors(Order order) {
    // Implementation to check if the order has errors
    // You can customize this logic based on your requirements

    // Example implementation:
    return order.HasErrors();
  }

  public static void handleAfterDelete(List<Order> deletedOrders) {
    Set<Id> accountIds = new Set<Id>();

    // Collect the Account IDs related to the deleted orders
    for (Order deletedOrder : deletedOrders) {
      accountIds.add(deletedOrder.AccountId);
    }

    // Check if there are any other orders related to the accounts
    List<Account> accountsToUpdate = new List<Account>();
    for (Id accountId : accountIds) {
      Integer relatedOrderCount = [
        SELECT COUNT()
        FROM Order
        WHERE AccountId = :accountId
      ];
      if (relatedOrderCount == 0) {
        accountsToUpdate.add(new Account(Id = accountId, Active__c = false));
      }
    }

    // Update the Active__c field on the related accounts
    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }
}
