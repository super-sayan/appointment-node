provider "kubernetes" {
  config_path    = "C:\\Users\\sorlo\\.kube\\config"
  config_context	= "docker-desktop"
}

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = "default"
  }
  data = {
    postgres-username = "cG9zdGdyZXM="
    postgres-password = "cats are best"
  }
}

resource "kubernetes_config_map" "db_config" {
  metadata {
    name      = "db-config"
    namespace = "default"

    labels = {
      app = "db"
    }
  }

  data = {
    POSTGRES_DB          = "appointmentdb"
    POSTGRES_PASSWORD    = base64decode(kubernetes_secret.postgres_secret.data["postgres-password"])
    POSTGRES_USER        = base64decode(kubernetes_secret.postgres_secret.data["postgres-username"])
  }
}

resource "kubernetes_config_map" "server_config" {
  metadata {
    name      = "server-config"
    namespace = "default"
  }

  data = {
    DB_HOST              = "db"
    DB_NAME              = "appointmentdb"
    POSTGRES_PASSWORD    = base64decode(kubernetes_secret.postgres_secret.data["postgres-password"])
    POSTGRES_USER        = base64decode(kubernetes_secret.postgres_secret.data["postgres-username"])
    DB_PORT              = "5432"
  }
}

resource "kubernetes_service" "server_service" {
  metadata {
    name      = "server-service"
    namespace = "default"
    labels = {
			app = "server"
		}
  }
  spec {
    selector = {
      app = "server"
    }
    port {
      protocol    = "TCP"
      port        = 4000
      target_port = 4000
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "server" {
  metadata {
    name      = "server"
    namespace = "default"
    labels = {
      app = "server"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "server"
      }
    }
    template {
      metadata {
        labels = {
          app = "server"
        }
      }
      spec {
        container {
          name  = "server"
          image = "sukurukun/happycatcafe-server:latest"
          image_pull_policy = "Always"
          port {
            container_port = 4000
            host_port = 4000
            protocol = "TCP"
          }
          env_from {
						config_map_ref {
						name = "server-config"
						}
					}
        }
      }
    }
  }
}

resource "kubernetes_deployment" "db" {
  metadata {
    name      = "db"
    namespace = "default"
    labels = {
      app = "db"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "db"
      }
    }
    template {
      metadata {
        labels = {
          app = "db"
        }
      }
      spec {
        container {
          name  = "db"
          image = "sukurukun/happycatcafe-db:latest"
          image_pull_policy = "Always"
          port {
            container_port = 5432
            protocol = "TCP"
            name = "db"
          }
          env_from {
						config_map_ref {
						name = "db-config"
						}
					}

          volume_mount {
						mount_path = "/var/lib/postgresql/data"
						name = "db-data"
					}

          volume_mount {
						mount_path = "/docker-entrypoint-initdb.d/"
						name = "db-volume"
					}
        }

        volume {
					name = "db-volume"
					host_path {
						path = "db"
					}
				}

        volume {
					name = "db-data"
					persistent_volume_claim {
						claim_name = "db-data"
					}
				}
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "db-data" {
	metadata {
		name = "db-data"
	}

	spec {
		access_modes = ["ReadWriteOnce"]

		resources {
			requests = {
				storage = "5Gi"
			}
		}
	}
}

resource "kubernetes_service" "db_service" {
  metadata {
    name      = "db-service"
    namespace = "default"
  }
  spec {
    selector = {
      app = "db"
    }
    port {
      name        = "5432"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "client" {
  metadata {
    name      = "client"
    namespace = "default"
    labels = {
      app = "client"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "client"
      }
    }
    template {
      metadata {
        labels = {
          app = "client"
        }
      }
      spec {
        container {
          name  = "client"
          image = "sukurukun/happycatcafe-client:latest"
          image_pull_policy = "Always"
          port {
            container_port = 3000
            host_port = 3000
            protocol = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "client_service" {
  metadata {
    name      = "client-balancer"
    namespace = "default"
    
    labels = {
      app = "client"
    }
  }
  spec {
    selector = {
      app = "client"
    }
    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }
    type = "LoadBalancer"
    load_balancer_ip = "127.0.0.1"
  }
}
