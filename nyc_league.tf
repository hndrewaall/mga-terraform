variable "nyc_league_version" {
  default = "0.6.1"
}

resource "aws_route53_record" "nyc_league" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "nyc-league"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "nyc_league" {
  family = "nyc_league"

  volume {
    name = "nyc_league-uwsgi"
  }

  volume {
    name = "nyc_league-db_data"
    host_path = "/var/lib/nyc_league/db"
  }

  container_definitions = <<EOF
[
  {
    "name": "nyc_league_app",
    "image": "${aws_ecr_repository.league_app.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_app.name}:${var.nyc_league_version}",
    "memoryReservation": 128,
    "essential": true,
    "links": ["nyc_league_db:db"],
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"},
      {"name": "SERVER_NAME", "value": "nyc-league.massgo.org"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.nyc_league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "app"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "nyc_league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_webserver",
    "image": "${aws_ecr_repository.league_webserver.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_webserver.name}:${var.nyc_league_version}",
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "nyc-league.massgo.org"}
    ],
    "essential": true,
    "memoryReservation": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "webserver"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "nyc_league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "nyc_league_db",
    "image": "${aws_ecr_repository.league_db.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_db.name}:${var.nyc_league_version}",
    "essential": true,
    "memoryReservation": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.nyc_league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "db"
      }
    },
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"}
    ],
    "mountPoints": [
      {
        "sourceVolume": "nyc_league-db_data",
        "containerPath": "/var/lib/league/db"
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "nyc_league" {
  name = "nyc_league"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.nyc_league.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "nyc_league" {
  name = "nyc_league"
}
