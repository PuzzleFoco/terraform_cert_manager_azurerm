# Cert-Manager

## Generell

>"cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing keypair, or self signed. 
It will ensure certificates are valid and up to date, and attempt to renew certificates at a configured time before expiry."

More information about Cert-Manager here: [Cert-Manager Doku](https://docs.cert-manager.io/en/latest/)

## Konstruktion

Der Cert-Manager ist dafür verantwortlich über via Let's Encrypt selbstständig Wildcard-Zertifikate für unsere Domain zu beantragen.

Das Vorgehen bestellt dabei aus vier Komponenten:
* Cert-Manager
* Secret für Cert-Manager
* ClusterIssuer
* Certificate

### Cert-Manager
Tool das mithilfe der anderen Komponenten in der Lage ist, eine sogenannte ACME-Challenge innerhalb der DNS-Zone der Domain zu erstellen. Diese ACME-Challenge dient für Let's Encrypt oder einer anderen Authentifizierungstelle, als Beweis der Domaininhaberschaft.

### Secret
Innerhalb des Secrets wird das Client_Secret gespeichert. Dieses ist nötig um den Cert-Manager zu berechtigen in der DNS-Zone die ACME-Challenge einzutragen.

### ClusterIssuer
ClusterIssuer sprechen die Zertifizierungstelle an und erfragen ein Zertifikat. Innerhalb des ClusterIssuers wird der Zertifizierungsserver (z.B. ein Test- oder Produktionsserver) und die Kontakt-E-Mail Adresse sowie alle nötigen Daten für die ACME-Challenge angegeben.

### Certificate
Das Zertifikat wird durch Let's Encrypt zertifiziert und kann dann dem Ingress mitgeteilt werden. Dieser wendet das Wildcard-Zertifikat dann für die komplette Domain an.


Das Zertifikat wird dem Ingress durch die Variable `controller.extraArgs.default-ssl-certificate` mitgegeben.


## Wichtig

In der obersten `variables.tf` wird eine E-Mail angegeben. Diese wird von Let's Encrypt und Co. verwendet um vor ablaufenden Zertifkaten zu warnen oder auf sontigem Weg mit dem Domain-Eigner in Kontakt zu treten.

Wenn das Zertifikat händisch, also durch ein Kubernetes yaml-File deployt wird, ist es wichtig das Password als base64 decodierte Daten mitzugeben. Wenn es allerdings als Terraform Ressource deployt wird, darf es nicht base64 codiert sein, sonst erhält der Cert-Manager keine Berechtigung für die DNS-Zone.

#### clientSecretSecretRef
Dieser Punkt wird innerhalb des ClusterIssuer festgelegt und muss ansich nicht händisch verändert werden. Trotzdem sollte festgehalten werden, dass dort als `key` der Name des Datenobjekts hinter welchem das Passwort innerhalb des Secrets gespeichert ist angegeben werden. In diesem Fall also das Wort "password".
`name` sollte der Name des Secrets sein.

Es ist grundsätzlich hilfreich, wenn alle Ressourcen innerhalb der selben Namespace befindlich sind.

## Quelle
Ein großer Teil der Arbeit wurde erleichtert durch dieses Tutorial.
https://github.com/fbeltrao/aks-letsencrypt/blob/master/setup-wildcard-certificates-with-azure-dns.md

Ebenso ist Dokumentation des Cert-Managers ebenfalls sehr hilfreich:
https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/azuredns.html