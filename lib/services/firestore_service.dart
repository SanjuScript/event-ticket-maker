  import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
 static final CollectionReference ticketsCollection =
      FirebaseFirestore.instance.collection('tickets');

 static Future<void> createTicket({
    required String name,
    required String phone,
    required int ticketCount,
    required String ticketId,
    required String paymentId,
  }) async {
    await ticketsCollection.doc(ticketId).set({
      'ticket_id': ticketId,
      'name': name,
      'phone': phone,
      'ticket_count': ticketCount,
      'payment_id':paymentId,
      'used': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot?> getTicketById(String ticketId) async {
    final doc = await ticketsCollection.doc(ticketId).get();
    return doc.exists ? doc : null;
  }

  Future<List<Map<String, dynamic>>> getTicketsByPhone(String phone) async {
    final querySnapshot = await ticketsCollection
        .where('phone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> markTicketAsUsed(String ticketId) async {
    await ticketsCollection.doc(ticketId).update({
      'used': true,
    });
  }
}
